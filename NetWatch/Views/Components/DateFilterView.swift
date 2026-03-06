import SwiftUI

struct DateFilterView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var startHour: Int
    @Binding var endHour: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("From")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 55, alignment: .trailing)
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .frame(width: 110)
                Picker("", selection: $startHour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d:00", h)).tag(h)
                    }
                }
                .frame(width: 80)
                Spacer()
            }

            HStack(spacing: 6) {
                Text("To")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 55, alignment: .trailing)
                DatePicker("", selection: $endDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .frame(width: 110)
                Picker("", selection: $endHour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d:59", h)).tag(h)
                    }
                }
                .frame(width: 80)
                Spacer()
            }

            HStack(spacing: 6) {
                quickButtons
                Spacer()
            }
        }
    }

    private var quickButtons: some View {
        HStack(spacing: 4) {
            quickButton("Today") {
                startDate = Date()
                endDate = Date()
                startHour = 0
                endHour = 23
            }
            quickButton("Yesterday") {
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                startDate = yesterday
                endDate = yesterday
                startHour = 0
                endHour = 23
            }
            quickButton("This Week") {
                let cal = Calendar.current
                let weekday = cal.component(.weekday, from: Date())
                startDate = cal.date(byAdding: .day, value: -(weekday - 2), to: Date())!
                endDate = Date()
                startHour = 0
                endHour = 23
            }
            quickButton("This Month") {
                let cal = Calendar.current
                startDate = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
                endDate = Date()
                startHour = 0
                endHour = 23
            }
        }
    }

    private func quickButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.cyan)
    }

    var dateRange: (from: Date, to: Date) {
        let cal = Calendar.current
        let from = cal.date(bySettingHour: startHour, minute: 0, second: 0, of: cal.startOfDay(for: startDate))!
        let to = cal.date(bySettingHour: endHour, minute: 59, second: 59, of: cal.startOfDay(for: endDate))!
        return (from, to)
    }
}
