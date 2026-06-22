import SwiftUI

// MARK: - Data Model

struct Category: Identifiable, Equatable {
    let id: String
    let symbol: String
}

// MARK: - Anchor Preference

struct CategoryPreference: Equatable {
    let category: Category
    let anchor: Anchor<CGRect>
}

struct CategoryPreferenceKey: PreferenceKey {
    static let defaultValue = [CategoryPreference]()

    static func reduce(value: inout [CategoryPreference], nextValue: () -> [CategoryPreference]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - CategoryButton

struct CategoryButton: View {
    var category: Category
    @Binding var selection: Category?

    var body: some View {
        Button {
            withAnimation { selection = category }
        } label: {
            VStack {
                Image(systemName: category.symbol)
                Text(category.id)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel(category.id)
        .anchorPreference(
            key: CategoryPreferenceKey.self,
            value: .bounds,
            transform: { [CategoryPreference(category: category, anchor: $0)] }
        )
    }
}

// MARK: - View

struct AnchorPreferencesView: View {
    @State private var selectedCategory: Category?

    let categories = [
        Category(id: "Arctic", symbol: "snowflake"),
        Category(id: "Beach", symbol: "beach.umbrella"),
        Category(id: "Shared Homes", symbol: "house"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Text("Anchor Preferences")
                        .font(.headline)
                    Text("카테고리 선택 시 밑줄이 애니메이션으로 이동\nAnchor<CGRect>로 기하 정보를 부모에 전달")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 20) {
                    ForEach(categories) { category in
                        CategoryButton(category: category, selection: $selectedCategory)
                    }
                }
                .overlayPreferenceValue(CategoryPreferenceKey.self) { preferences in
                    GeometryReader { proxy in
                        if let selected = preferences.first(where: { $0.category == selectedCategory }) {
                            let frame = proxy[selected.anchor]

                            Rectangle()
                                .fill(.primary)
                                .frame(width: frame.width, height: 2)
                                .position(x: frame.midX, y: frame.maxY)
                        }
                    }
                }

                List(categories, id: \.id) { category in
                    HStack {
                        Button(category.id) {
                            withAnimation { selectedCategory = category }
                        }
                        if selectedCategory == category {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .frame(height: 200)

                if let selectedCategory {
                    Text("Selected: \(selectedCategory.id)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Anchor Preferences")
    }
}

#Preview {
    NavigationStack {
        AnchorPreferencesView()
    }
}
