import SwiftUI
import Charts
import GRDB

struct HistoryView: View {
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var startHour = 0
    @State private var endHour = 23
    @State private var appSummaries: [AppUsageSummary] = []
    @State private var hourlyData: [HourlyUsage] = []
    @State private var totalIn: Int64 = 0
    @State private var totalOut: Int64 = 0

    private var isSingleDay: Bool {
        Calendar.current.isDate(startDate, inSameDayAs: endDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            DateFilterView(
                startDate: $startDate,
                endDate: $endDate,
                startHour: $startHour,
                endHour: $endHour
            )
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .onChange(of: startDate) { loadData() }
            .onChange(of: endDate) { loadData() }
            .onChange(of: startHour) { loadData() }
            .onChange(of: endHour) { loadData() }

            Divider()

            totalHeader

            Divider().padding(.vertical, 2)

            if !hourlyData.isEmpty && isSingleDay {
                hourlyChart
                    .padding(.horizontal)
                    .frame(height: 120)
                Divider().padding(.vertical, 2)
            }

            appList
        }
        .onAppear { loadData() }
    }

    private var totalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatter.format(totalIn + totalOut))
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            Spacer()
            HStack(spacing: 16) {
                Label(ByteFormatter.format(totalIn), systemImage: "arrow.down")
                    .foregroundStyle(.cyan)
                Label(ByteFormatter.format(totalOut), systemImage: "arrow.up")
                    .foregroundStyle(.orange)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var hourlyChart: some View {
        Chart(hourlyData) { item in
            BarMark(
                x: .value("Hour", "\(item.hour):00"),
                y: .value("Usage", item.totalBytes)
            )
            .foregroundStyle(.cyan.gradient)
            .cornerRadius(2)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let bytes = value.as(Int64.self) {
                        Text(ByteFormatter.format(bytes))
                            .font(.system(size: 8))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 8)) { _ in
                AxisValueLabel()
                    .font(.system(size: 8))
            }
        }
    }

    private var appList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if appSummaries.isEmpty {
                    Text("No data for this period")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding(.top, 40)
                } else {
                    ForEach(appSummaries) { app in
                        appRow(app)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func appRow(_ app: AppUsageSummary) -> some View {
        HStack {
            Image(systemName: "app.fill")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.system(.caption, weight: .medium))
                    .lineLimit(1)

                UsageBarView(
                    value: app.totalBytes,
                    maxValue: appSummaries.first?.totalBytes ?? 1,
                    color: .cyan
                )
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(ByteFormatter.format(app.totalBytes))
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                HStack(spacing: 4) {
                    Text("\u{2193}\(ByteFormatter.format(app.totalBytesIn))")
                    Text("\u{2191}\(ByteFormatter.format(app.totalBytesOut))")
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary.opacity(0.3))
        )
    }

    private func loadData() {
        let filter = DateFilterView(
            startDate: $startDate,
            endDate: $endDate,
            startHour: $startHour,
            endHour: $endHour
        )
        let range = filter.dateRange

        do {
            try DatabaseManager.shared.reader.read { db in
                appSummaries = try UsageQueries.appUsageForDateRange(db: db, from: range.from, to: range.to)
                let totals = try UsageQueries.totalUsageForDateRange(db: db, from: range.from, to: range.to)
                totalIn = totals.bytesIn
                totalOut = totals.bytesOut

                if isSingleDay {
                    hourlyData = try UsageQueries.hourlyUsageForDate(db: db, date: startDate)
                } else {
                    hourlyData = []
                }
            }
        } catch {}
    }
}
