import SwiftUI

struct CategoryFilterSheet: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    let onDeleteCategory: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var categoryToDelete: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHandle
            Text("Filtrera")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 16)
                .padding(.bottom, 16)

            filterRow(label: "Alla", value: nil, icon: "square.grid.2x2")

            ForEach(categories, id: \.self) { cat in
                filterRow(label: cat, value: cat, icon: "tag")
            }
        }
        .padding(.horizontal, 20)
        .alert("Radera kategori?", isPresented: .init(
            get: { categoryToDelete != nil },
            set: { if !$0 { categoryToDelete = nil } }
        )) {
            Button("Avbryt", role: .cancel) {}
            Button("Radera", role: .destructive) {
                if let cat = categoryToDelete {
                    onDeleteCategory(cat)
                }
            }
        } message: {
            if let cat = categoryToDelete {
                Text("Kategorin \"\(cat)\" tas bort från alla påminnelser som använder den.")
            }
        }
    }

    private func filterRow(label: String, value: String?, icon: String) -> some View {
        let isSelected = selectedCategory == value
        return Button {
            selectedCategory = value
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? AppTheme.accentColor : AppTheme.textSecondary)
                Text(label)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.accentColor : AppTheme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.accentColor)
                }
                if value != nil {
                    Button {
                        categoryToDelete = value
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? AppTheme.accentColor.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var sheetHandle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
    }
}
