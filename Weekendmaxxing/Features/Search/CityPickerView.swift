import SwiftUI

/// A searchable list for choosing a destination city.
struct CityPickerView: View {
    let cities: [City]
    @Binding var selection: City?

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [City] {
        guard !query.isEmpty else { return cities }
        return cities.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.country.localizedCaseInsensitiveContains(query)
                || $0.code.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { city in
                Button {
                    selection = city
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(city.flagEmoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(city.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(city.country)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selection?.code == city.code {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Brand.coral)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search city or country")
            .navigationTitle("Choose destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
