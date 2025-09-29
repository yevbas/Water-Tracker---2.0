//
//  MetricView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI

struct MetricView: View {
    @State var selectedAnswer: Answer?

    struct Configuration: Hashable, Identifiable {
        var id: String
        var title: String
        var question: String
        var answerType: AnswerType
    }

    enum AnswerType: Hashable {
        case strings(_ answers: [Answer])
        case selection(_ range: [Answer])
    }

    struct Answer: Hashable {
        var value: String
        var title: String
    }

    var configuration: Configuration

    var onSubmit: (Answer?) -> Void = { _ in }

    init(
        selectedAnswer: Answer? = nil,
        configuration: Configuration,
        onSubmit: @escaping (Answer?) -> Void = { _ in }
    ) {
        self._selectedAnswer = .init(
            initialValue: selectedAnswer
        )
        self.configuration = configuration
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(configuration.title)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(configuration.question)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            Spacer()
            switch configuration.answerType {
            case .strings(let strings):
                VStack(spacing: 16) {
                    ForEach(strings, id: \.self) { answer in
                        AnswerButton(
                            answer: answer.title,
                            isSelected: selectedAnswer == answer
                        )
                        .onTapGesture {
                            selectedAnswer = answer
                        }
                    }
                }
            case .selection(let range):
                GroupBox {
                    Picker("", selection: $selectedAnswer) {
                        ForEach(range, id: \.self) { item in
                            Text(item.title)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            Spacer()
            PrimaryButton(
                title: String(localized: "Continue"),
                isDisabled: selectedAnswer == nil
            ) {
                onSubmit(selectedAnswer)
            }
        }
        .padding(.horizontal)
        .animation(.smooth, value: selectedAnswer)
    }

    struct AnswerButton: View {
        var answer: String
        var isSelected: Bool = false

        var body: some View {
            Text(answer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .font(.body.weight(.medium))
                .foregroundColor(isSelected ? .white : .black)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(LinearGradient(colors: [.yellow, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(.ultraThinMaterial)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
    }

}

#Preview {
    VStack(spacing: 24) {
        ProgressView()
            .progressViewStyle(.linear)
            .padding()
        MetricView(
            selectedAnswer: .init(value: "2", title: "2"),
            configuration: .init(
                id: "goal",
                title: "Creating custom plan.",
                question: "What's your goal?",
                answerType: .selection(
                    [.init(value: "1", title: "1"),
                    .init(value: "2", title: "2"),
                    .init(value: "3", title: "3")]
                )
            )
        )
    }
}
