//
//  CategoryPickerField.swift
//  Sidequest
//

import SwiftUI

struct CategoryPickerField: View {
    @Binding var category: String
    var customCategories: [String] = []

    @State private var isExpanded = false
    @FocusState private var isFocused: Bool

    private var suggestions: [String] {
        let all = CategoryHelper.predefinedNames + customCategories.filter { name in
            !CategoryHelper.predefinedNames.contains(name)
        }
        if category.isEmpty { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(category) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: CategoryHelper.icon(for: category))
                    .foregroundStyle(.blue)
                    .font(.body)
                    .frame(width: 24)

                TextField("Kategorie eingeben...", text: $category)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isFocused)

                if !category.isEmpty {
                    Button {
                        category = ""
                        isFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isFocused && !suggestions.isEmpty {
                Divider()
                    .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions, id: \.self) { name in
                            Button {
                                category = name
                                isFocused = false
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: CategoryHelper.icon(for: name))
                                        .foregroundStyle(.blue)
                                        .font(.caption)
                                        .frame(width: 20)
                                    Text(name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if name != suggestions.last {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }
}
