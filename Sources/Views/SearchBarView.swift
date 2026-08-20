import SwiftUI

public enum FilterCategory: String, CaseIterable {
    case all = "全部"
    case text = "文本"
    case image = "图片"
    case pinned = "收藏"
}

public struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var selectedCategory: FilterCategory

    public init(searchText: Binding<String>, selectedCategory: Binding<FilterCategory>) {
        self._searchText = searchText
        self._selectedCategory = selectedCategory
    }

    public var body: some View {
        VStack(spacing: 8) {
            // 搜索框
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13, weight: .medium))

                TextField("搜索剪切板历史...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 1)
            )

            // 分类筛选 Pills
            HStack(spacing: 6) {
                ForEach(FilterCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCategory = category
                        }
                    }) {
                        Text(category.rawValue)
                            .font(.system(size: 11, weight: selectedCategory == category ? .semibold : .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(
                                selectedCategory == category
                                ? Color.accentColor.opacity(0.18)
                                : Color(NSColor.controlBackgroundColor).opacity(0.5)
                            )
                            .foregroundColor(
                                selectedCategory == category
                                ? Color.accentColor
                                : Color.secondary
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedCategory == category ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}
