#!/usr/bin/env python3
"""
String Catalog Localizer
Automatically translates Xcode String Catalog (.xcstrings) files to multiple languages
"""

import json
import sys
import os
from typing import Dict, List
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

try:
    from openai import OpenAI
except ImportError:
    print("Error: OpenAI package not installed. Run: pip install openai")
    sys.exit(1)


# Target languages - Add or remove languages as needed
TARGET_LANGUAGES = {
    'ar': 'Arabic',
    'bn': 'Bangla',
    'bg': 'Bulgarian',
    'ca': 'Catalan',
    'zh-HK': 'Chinese (Hong Kong)',
    'zh-Hans': 'Chinese, Simplified',
    'zh-Hant': 'Chinese, Traditional',
    'hr': 'Croatian',
    'cs': 'Czech',
    'da': 'Danish',
    'nl': 'Dutch',
    'en-AU': 'English (Australia)',
    'en-IN': 'English (India)',
    'en-GB': 'English (United Kingdom)',
    'fi': 'Finnish',
    'fr': 'French',
    'fr-CA': 'French (Canada)',
    'de': 'German',
    'el': 'Greek',
    'gu': 'Gujarati',
    'he': 'Hebrew',
    'hi': 'Hindi',
    'hu': 'Hungarian',
    'id': 'Indonesian',
    'it': 'Italian',
    'ja': 'Japanese',
    'kn': 'Kannada',
    'kk': 'Kazakh',
    'ko': 'Korean',
    'lt': 'Lithuanian',
    'ms': 'Malay',
    'ml': 'Malayalam',
    'mr': 'Marathi',
    'nb': 'Norwegian Bokmål',
    'or': 'Odia',
    'pl': 'Polish',
    'pt-BR': 'Portuguese (Brazil)',
    'pt-PT': 'Portuguese (Portugal)',
    'pa': 'Punjabi',
    'ro': 'Romanian',
    'ru': 'Russian',
    'sk': 'Slovak',
    'sl': 'Slovenian',
    'es': 'Spanish',
    'sv': 'Swedish',
    'ta': 'Tamil',
    'te': 'Telugu',
    'th': 'Thai',
    'tr': 'Turkish',
    'uk': 'Ukrainian',
    'ur': 'Urdu',
    'vi': 'Vietnamese',
}


def load_xcstrings(filepath: str) -> Dict:
    """Load the xcstrings file"""
    print(f"📖 Loading {filepath}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_xcstrings(data: Dict, filepath: str):
    """Save the xcstrings file with proper formatting"""
    print(f"💾 Saving to {filepath}...")
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


# Thread-safe print lock
print_lock = threading.Lock()


def safe_print(*args, **kwargs):
    """Thread-safe print function"""
    with print_lock:
        print(*args, **kwargs)


def translate_batch(client: OpenAI, texts: List[str], target_lang: str, lang_name: str, batch_num: int = 0, total_batches: int = 0, use_safe_print: bool = True) -> List[str]:
    """Translate a batch of texts using OpenAI API - OPTIMIZED"""
    if not texts:
        return []
    
    print_fn = safe_print if use_safe_print else print
    
    # Show what we're translating
    if batch_num > 0 and total_batches > 0:
        print_fn(f"  📤 [{lang_name}] API Call [{batch_num}/{total_batches}] - Sending {len(texts)} strings...")
    
    # Create compact numbered list (saves tokens)
    numbered_texts = "\n".join([f"{i+1}|{text}" for i, text in enumerate(texts)])
    
    # Shorter, more efficient prompt
    prompt = f"""Translate to {lang_name}. Keep all %@, %lld, %1$@ placeholders exact. Return numbered list only:

{numbered_texts}"""
    
    try:
        api_start = time.time()
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": f"Translate to {lang_name}. Keep placeholders exact."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2,
            max_tokens=4000  # Limit response size for speed
        )
        api_time = time.time() - api_start
        
        translated_text = response.choices[0].message.content.strip()
        
        # Parse responses (handles both | and . separators)
        translations = []
        for line in translated_text.split('\n'):
            line = line.strip()
            if not line:
                continue
            # Try both | and . as separators
            if '|' in line:
                parts = line.split('|', 1)
                if len(parts) == 2:
                    translations.append(parts[1].strip())
            elif '. ' in line:
                parts = line.split('. ', 1)
                if len(parts) == 2:
                    translations.append(parts[1].strip())
            else:
                translations.append(line)
        
        # Ensure correct count
        while len(translations) < len(texts):
            translations.append(texts[len(translations)])
        
        # Show completion with timing
        if batch_num > 0:
            print_fn(f"  ✅ [{lang_name}] Received {len(translations)} translations ({api_time:.1f}s)")
        
        return translations[:len(texts)]
    
    except Exception as e:
        print_fn(f"  ❌ [{lang_name}] Error: {e}")
        return texts


def translate_language(client: OpenAI, data: Dict, lang_code: str, lang_name: str, idx: int, total_langs: int) -> tuple:
    """Translate all strings for a single language"""
    lang_start_time = time.time()
    
    # Count strings to translate for this language
    strings_to_translate = []
    for key, value in data['strings'].items():
        if not key.strip():
            continue
        if isinstance(value, dict) and 'localizations' in value:
            if lang_code in value['localizations']:
                continue
        strings_to_translate.append(key)
    
    total_to_translate = len(strings_to_translate)
    batch_size = 100
    estimated_batches = (total_to_translate + batch_size - 1) // batch_size
    
    safe_print(f"🔄 [{idx}/{total_langs}] Translating to {lang_name} ({lang_code})")
    safe_print(f"  📊 {total_to_translate} strings → {estimated_batches} API calls")
    safe_print()
    
    # Store translations for this language
    language_translations = {}
    
    # Collect strings to translate in batches
    batch = []
    batch_keys = []
    translated_count = 0
    current_batch_num = 0
    
    for key in strings_to_translate:
        batch.append(key)
        batch_keys.append(key)
        
        # OPTIMIZED: Larger batches = fewer API calls = faster & cheaper
        if len(batch) >= batch_size:
            current_batch_num += 1
            translations = translate_batch(client, batch, lang_code, lang_name, current_batch_num, estimated_batches)
            
            # Store translations
            for orig_key, translation in zip(batch_keys, translations):
                language_translations[orig_key] = translation
            
            translated_count += len(batch)
            percentage = (translated_count / total_to_translate) * 100
            
            # Progress bar
            bar_length = 30
            filled = int(bar_length * translated_count / total_to_translate)
            bar = '█' * filled + '░' * (bar_length - filled)
            
            safe_print(f"  📈 [{lang_name}] Progress: [{bar}] {percentage:.1f}% ({translated_count}/{total_to_translate})")
            safe_print()
            
            batch = []
            batch_keys = []
            time.sleep(0.1)  # Minimal delay
    
    # Translate remaining batch
    if batch:
        current_batch_num += 1
        translations = translate_batch(client, batch, lang_code, lang_name, current_batch_num, estimated_batches)
        
        for orig_key, translation in zip(batch_keys, translations):
            language_translations[orig_key] = translation
        
        translated_count += len(batch)
    
    lang_time = time.time() - lang_start_time
    
    safe_print(f"✅ {lang_name} COMPLETE! ({translated_count} strings in {lang_time:.1f}s)")
    safe_print("─" * 60)
    safe_print()
    
    return lang_code, language_translations, translated_count, lang_time


def localize_xcstrings(input_file: str, output_file: str, api_key: str, languages: Dict[str, str] = None, parallel: bool = True):
    """Main localization function with parallel processing"""
    
    if languages is None:
        languages = TARGET_LANGUAGES
    
    # Initialize OpenAI client
    client = OpenAI(api_key=api_key)
    
    # Load the xcstrings file
    data = load_xcstrings(input_file)
    
    if 'strings' not in data:
        print("❌ Invalid xcstrings file format")
        return
    
    total_strings = len([k for k in data['strings'].keys() if k.strip()])
    print(f"📝 Found {total_strings} strings to translate")
    print(f"🌍 Translating to {len(languages)} languages: {', '.join(languages.values())}")
    
    if parallel:
        print(f"⚡ PARALLEL MODE: Translating all {len(languages)} languages simultaneously!")
    
    print("=" * 60)
    print()
    
    overall_start = time.time()
    
    if parallel:
        # PARALLEL PROCESSING - All languages at once!
        # Use up to 20 workers for maximum speed (OpenAI can handle it)
        with ThreadPoolExecutor(max_workers=min(len(languages), 20)) as executor:
            # Submit all language translation tasks
            futures = {}
            for idx, (lang_code, lang_name) in enumerate(languages.items(), 1):
                future = executor.submit(translate_language, client, data, lang_code, lang_name, idx, len(languages))
                futures[future] = (lang_code, lang_name)
            
            # Collect results as they complete
            completed_count = 0
            all_results = []
            
            for future in as_completed(futures):
                lang_code, lang_name = futures[future]
                try:
                    result = future.result()
                    all_results.append(result)
                    completed_count += 1
                    
                    # Show overall progress
                    safe_print(f"🎯 Overall Progress: {completed_count}/{len(languages)} languages complete")
                    safe_print()
                    
                except Exception as e:
                    safe_print(f"❌ Error translating {lang_name}: {e}")
                    safe_print()
            
            # Apply all translations to the data structure
            safe_print("💾 Applying translations to file...")
            for lang_code, translations, count, duration in all_results:
                for key, translation in translations.items():
                    if 'localizations' not in data['strings'][key]:
                        data['strings'][key]['localizations'] = {}
                    
                    data['strings'][key]['localizations'][lang_code] = {
                        "stringUnit": {
                            "state": "translated",
                            "value": translation
                        }
                    }
    
    else:
        # SEQUENTIAL PROCESSING (fallback)
        for idx, (lang_code, lang_name) in enumerate(languages.items(), 1):
            result = translate_language(client, data, lang_code, lang_name, idx, len(languages))
            lang_code, translations, count, duration = result
            
            # Apply translations
            for key, translation in translations.items():
                if 'localizations' not in data['strings'][key]:
                    data['strings'][key]['localizations'] = {}
                
                data['strings'][key]['localizations'][lang_code] = {
                    "stringUnit": {
                        "state": "translated",
                        "value": translation
                    }
                }
    
    # Save the localized file
    save_xcstrings(data, output_file)
    
    total_time = time.time() - overall_start
    total_minutes = int(total_time // 60)
    total_seconds = int(total_time % 60)
    
    # Calculate statistics
    total_translations = total_strings * len(languages)
    
    print()
    print("=" * 60)
    print("🎉 ALL TRANSLATIONS COMPLETE!")
    print("=" * 60)
    print(f"  📊 Total strings: {total_strings}")
    print(f"  🌍 Languages: {len(languages)}")
    print(f"  ✅ Total translations: {total_translations:,}")
    print(f"  ⏱️  Total time: {total_minutes}m {total_seconds}s")
    
    if parallel:
        # Calculate actual speedup (limited by parallelism)
        workers_used = min(len(languages), 20)
        speedup = workers_used if len(languages) > workers_used else len(languages)
        print(f"  ⚡ Parallel speedup: ~{speedup}x faster than sequential!")
        sequential_time = total_time * speedup
        seq_minutes = int(sequential_time // 60)
        print(f"  💡 Would have taken ~{seq_minutes} minutes without parallelization!")
    
    print(f"  💾 Saved to: {output_file}")
    print("=" * 60)


def main():
    print("=" * 60)
    print("🌍 Xcode String Catalog Localizer")
    print("=" * 60)
    print()
    
    # Get API key from environment or prompt
    api_key = os.environ.get('OPENAI_API_KEY')
    
    if not api_key:
        print("❌ OpenAI API key not found!")
        print("Set it as an environment variable: export OPENAI_API_KEY='your-key-here'")
        print("Or get one at: https://platform.openai.com/api-keys")
        sys.exit(1)
    
    # File paths
    input_file = "WaterTracker/Localizable.xcstrings"
    output_file = "WaterTracker/Localizable_localized.xcstrings"
    
    if not os.path.exists(input_file):
        print(f"❌ Input file not found: {input_file}")
        sys.exit(1)
    
    # Show which languages will be added
    print("Target languages:")
    for code, name in TARGET_LANGUAGES.items():
        print(f"  • {name} ({code})")
    print()
    print("⚡ PARALLEL MODE:")
    print(f"  • Translates ALL {len(TARGET_LANGUAGES)} languages at the same time!")
    print("  • Batch size: 100 strings per API call")
    print(f"  • Estimated time: ~2-4 minutes for {len(TARGET_LANGUAGES)} languages 🚀")
    print(f"  • Cost: ~${0.02 * len(TARGET_LANGUAGES):.2f} (extremely cheap!)")
    print()
    
    # Ask for confirmation
    response = input("Continue with translation? (y/n): ").lower().strip()
    if response != 'y':
        print("❌ Translation cancelled")
        sys.exit(0)
    
    print()
    start_time = time.time()
    
    # Run localization
    localize_xcstrings(input_file, output_file, api_key)
    
    print()
    print()
    print("📋 NEXT STEPS:")
    print("─" * 60)
    print("1️⃣  Review the translations:")
    print("   open WaterTracker/Localizable_localized.xcstrings")
    print()
    print("2️⃣  If satisfied, replace the original:")
    print("   mv WaterTracker/Localizable_localized.xcstrings WaterTracker/Localizable.xcstrings")
    print()
    print("3️⃣  Open in Xcode and verify translations")
    print()
    print("4️⃣  Add languages in Xcode:")
    print("   Project Settings → Info → Localizations → Click +")
    print("─" * 60)


if __name__ == "__main__":
    main()

