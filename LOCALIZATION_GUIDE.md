# 🌍 String Catalog Localization Guide

## Quick Start (5 minutes)

### Step 1: Install Python Dependencies
```bash
cd /Users/jacksonsmac/Desktop/WaterTracker
pip3 install -r requirements.txt
```

### Step 2: Get OpenAI API Key
1. Go to https://platform.openai.com/api-keys
2. Create an account (if you don't have one)
3. Click "Create new secret key"
4. Copy the key (it starts with `sk-`)

### Step 3: Set Your API Key
```bash
export OPENAI_API_KEY='sk-your-key-here'
```

### Step 4: Run the Script
```bash
python3 localize_strings.py
```

The script will:
- ✅ Read your `Localizable.xcstrings` file
- ✅ Translate to 15 languages automatically
- ✅ Save to `Localizable_localized.xcstrings`
- ✅ Preserve all formatting and placeholders

### Step 5: Apply the Translations
After reviewing the translations:
```bash
mv WaterTracker/Localizable_localized.xcstrings WaterTracker/Localizable.xcstrings
```

### Step 6: Add Languages in Xcode
1. Open your project in Xcode
2. Select the project in the navigator
3. Go to **Info** tab
4. Under **Localizations**, click **+** to add languages:
   - Spanish
   - French
   - German
   - Italian
   - Portuguese (Brazil)
   - Japanese
   - Korean
   - Chinese (Simplified)
   - Chinese (Traditional)
   - Arabic
   - Russian
   - Hindi
   - Dutch
   - Swedish
   - Polish

---

## 📝 Customization

### Change Target Languages
Edit `localize_strings.py` and modify the `TARGET_LANGUAGES` dictionary:

```python
TARGET_LANGUAGES = {
    'es': 'Spanish',
    'fr': 'French',
    # Add or remove languages here
}
```

### Available Language Codes
Common iOS language codes:
- `es` - Spanish
- `fr` - French
- `de` - German
- `it` - Italian
- `pt-BR` - Portuguese (Brazil)
- `pt-PT` - Portuguese (Portugal)
- `ja` - Japanese
- `ko` - Korean
- `zh-Hans` - Chinese (Simplified)
- `zh-Hant` - Chinese (Traditional)
- `ar` - Arabic
- `ru` - Russian
- `hi` - Hindi
- `nl` - Dutch
- `sv` - Swedish
- `da` - Danish
- `no` - Norwegian
- `fi` - Finnish
- `pl` - Polish
- `tr` - Turkish
- `th` - Thai
- `vi` - Vietnamese
- `id` - Indonesian

---

## 💰 Cost Estimate

Using GPT-4o-mini (the script's default):
- **~$0.10 - $0.50** for the entire project
- Very affordable for one-time translation

---

## 🔧 Troubleshooting

### "OpenAI API key not found"
Make sure you've set the environment variable:
```bash
export OPENAI_API_KEY='your-key-here'
```

### "Module not found: openai"
Install the requirements:
```bash
pip3 install -r requirements.txt
```

### Rate Limit Errors
The script includes rate limiting, but if you hit limits:
- Wait a few minutes
- Run the script again (it skips already translated strings)

### Wrong Translations
- Edit the `Localizable.xcstrings` file manually in Xcode
- Or re-run with specific languages only

---

## 📊 What Gets Translated

The script translates **all English strings** in your String Catalog, including:
- Button labels
- Error messages
- UI text
- Notifications
- Comments and descriptions

It **preserves**:
- String interpolation (`%@`, `%lld`, etc.)
- Positional arguments (`%1$@`, `%2$@`)
- Newlines and formatting
- Special characters

---

## 🎯 Alternative: Use Specific Languages Only

Edit the script to translate only specific languages:

```python
# At the top of localize_strings.py, replace TARGET_LANGUAGES with:
TARGET_LANGUAGES = {
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
}
```

Then run the script normally.

---

## ✨ Pro Tips

1. **Review before applying**: Always check `Localizable_localized.xcstrings` before replacing the original
2. **Version control**: Commit your original file first so you can revert if needed
3. **Test in-app**: Use Xcode's language scheme to test each translation
4. **Professional review**: For production apps, have native speakers review critical strings

---

## Need Help?

- API issues: https://platform.openai.com/docs
- Xcode localization: https://developer.apple.com/documentation/xcode/localization

