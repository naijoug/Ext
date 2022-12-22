//
//  Date+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import Foundation

extension Date: ExtCompatible {}

public extension ExtWrapper where Base == Date {

    /// 日期格式化类型
    enum DateFormatType: String {
        /// yyyy-MM-dd HH:mm:ss SSS
        case yyyy_MM_dd_HH_mm_ss_SSS    = "yyyy-MM-dd HH:mm:ss SSS"
        /// yyyyMMdd_HHmmss_SSS
        case yyyyMMdd_HHmmss_SSS        = "yyyyMMdd_HHmmss_SSS"
        /// yyyy-MM-dd HH:mm:ss
        case yyyy_MM_dd_HH_mm_ss        = "yyyy-MM-dd HH:mm:ss"
        /// yyMMdd_HHmmss_SSS
        case yyMMdd_HHmmss_SSS          = "yyMMdd_HHmmss_SSS"
        /// MM/dd/yyyy HH:mm:ss
        case MMddyyyy_HH_mm_ss          = "MM/dd/yyyy HH:mm:ss"
        /// dd/MM/yyyy HH:mm:ss
        case ddMMyyy_HH_mm_ss           = "dd/MM/yyyy HH:mm:ss"
        /// MM/dd HH:ss
        case MMdd_HH_mm                 = "MM/dd HH:mm"
        /// yyyy-MM-dd
        case yyyy_MM_dd                 = "yyyy-MM-dd"
        /// MM/dd/yyyy
        case MMddyyyy                   = "MM/dd/yyyy"
        /// HH:mm:ss SSS
        case HH_mm_ss_SSS               = "HH:mm:ss SSS"
        /// HH:mm:ss
        case HH_mm_ss                   = "HH:mm:ss"
        /// mm:ss
        case mm_ss                      = "mm:ss"
    }
    
    /// Date -> String
    /// - Parameter type: 日期格式类型
    func format(type: DateFormatType) -> String {
        return format(type.rawValue)
    }
    
    /**
     Reference:
        - https://developer.apple.com/documentation/foundation/dateformatter
        - https://stackoverflow.com/questions/31469172/show-am-pm-in-capitals-in-swift
     */
    
    /// Date -> String
    ///
    /// - Parameter dateFormat: 日期格式 [eg: yyyy-MM-dd HH:mm:ss SSS]
    /// - Returns: String
    func format(_ dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = dateFormat
        return formatter.string(from: base)
    }
    
    /// log日志时间
    var logTime: String {
        return format(type: .yyyy_MM_dd_HH_mm_ss_SSS)
    }
    
}

public extension ExtWrapper where Base == Date {
    
    /// 格式化时间戳 yyyy-MM-dd HH:mm:ss SSS
    static func formatTime(_ timestamp: TimeInterval?, format: String) -> String? {
        guard let date = dateTime(timestamp) else { return nil }
        return date.ext.format(format)
    }
    
    /// 时间戳 -> Date
    static func dateTime(_ timestamp: TimeInterval?) -> Date? {
        guard let timestamp = timestamp else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    /// 当前时间基础上调整时间
    func dateWith(day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) -> Date {
        let components = DateComponents(day: day, hour: hour, minute: minute, second: second)
        return Calendar.current.date(byAdding: components, to: base) ?? base
    }
    
    /// 当前时间与目标时间戳相差天数
    /// - Parameter timestamp: 时间戳
    /// - Returns: 返回相差天数
    static func days(with timestamp: TimeInterval?) -> Int? {
        guard let timestamp = timestamp, let date = dateTime(timestamp) else { return nil }
        let current = Date()
        let isFuture = timestamp > current.timeIntervalSince1970
        let components = Calendar.current.dateComponents([.day], from: isFuture ? current : date, to: isFuture ? date : current)
        return components.day
    }
    
    static func dayTo(_ timestamp: TimeInterval?) -> Int? {
        guard let date = dateTime(timestamp) else { return nil }
        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: date)
        return components.day
    }
}

public extension ExtWrapper where Base == Date {

    /**
     Reference:
        - https://stackoverflow.com/questions/43663622/is-a-date-in-same-week-month-year-of-another-date-in-swift
        - https://github.com/melvitax/DateHelper
     */
    
    /// 未来时间
    var isFuture: Bool { base > Date() }
    /// 过去时间
    var isPast:   Bool { base < Date() }
    
    /// 日期组成 [年、月、日、周、时、分、秒]
    var dateComponents: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .weekday, .hour, .minute, .second], from: base)
    }
    
    /// 明天
    var isTomorrow:  Bool { Calendar.current.isDateInTomorrow(base) }
    /// 今天
    var isToday:     Bool { Calendar.current.isDateInToday(base) }
    /// 昨天
    var isYesterday: Bool { Calendar.current.isDateInYesterday(base) }
    /// 前天
    var isTwoDaysAgo: Bool { return isSameDay(date: Date().addingTimeInterval(-ExtWrapper<Date>.oneDayOfSeconds*2)) }
    /// 本周
    var isThisWeek: Bool {
        let seconds = Date().timeIntervalSince(base)
        guard 0 <= seconds && seconds < ExtWrapper<Date>.oneWeekOfSeconds else { return false }
        return true
    }
    /// 上周
    var isLastWeek: Bool  {
        let seconds = Date().timeIntervalSince(base)
        guard ExtWrapper<Date>.oneWeekOfSeconds <= seconds && seconds < ExtWrapper<Date>.oneWeekOfSeconds*2 else { return false }
        return true
    }
    /// 本月
    var isThisMonth: Bool { isSameMonth(date: Date()) }
    /// 上个月
    var isLastMonth: Bool {
        var components = DateComponents()
        components.month = -1
        guard let date = Calendar.current.date(byAdding: components, to: Date()) else { return false }
        return isSameMonth(date: date)
    }
    /// 今年
    var isThisYear: Bool  { isSameYear(date: Date()) }
    
    /// 年月日是否相等
    func equalYMD(_ other: Date) -> Bool {
        let nowComp = self.dateComponents
        let otherComp = other.ext.dateComponents
        return (nowComp.year == otherComp.year)
            && (nowComp.month == otherComp.month)
            && (nowComp.day == otherComp.day)
    }
    
    /// 一分钟的秒数 (60秒)
    private static let oneMinuteOfSeconds: TimeInterval = 60
    /// 一个小时的秒数 (60分钟)
    private static let oneHourOfSeconds: TimeInterval = oneMinuteOfSeconds * 60
    /// 一天的秒数 (24小时)
    private static let oneDayOfSeconds: TimeInterval = oneHourOfSeconds * 24
    /// 一周的秒数 (7天)
    private static let oneWeekOfSeconds: TimeInterval = oneDayOfSeconds * 7
}

public extension ExtWrapper where Base == Date {
    
    /// 同一天
    func isSameDay  (date: Date) -> Bool { isEqual(to: date, toGranularity: .day) }
    /// 同一个月
    func isSameMonth(date: Date) -> Bool { isEqual(to: date, toGranularity: .month) }
    /// 同一年
    func isSameYear (date: Date) -> Bool { isEqual(to: date, toGranularity: .year) }
    
    /// 日期相等比较
    private func isEqual(to date: Date, toGranularity component: Calendar.Component, in calendar: Calendar = .current) -> Bool {
        calendar.isDate(base, equalTo: date, toGranularity: component)
    }
}

public extension ExtWrapper where Base == Date {
    /// 当前月份天数
    var daysInMonth: Int? {
        Calendar.current.range(of: .day, in: .month, for: base)?.count
    }
    
    /// 改时间下一个整点时间
    var nextOclock: Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: base)
        let second = calendar.component(.second, from: base)
        let components = DateComponents(hour: 1, minute: -minute, second: -second)
        return calendar.date(byAdding: components, to: base) ?? base
    }
    /// 该时间的零点
    var zeroOclock: Date {
        Calendar.current.startOfDay(for: base)
    }
    /// 改时间的下一个零点时间
    var nextZeroOclock: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: base.ext.zeroOclock) ?? base
    }
    
    /// 该时间所在周的第一天日期
    var startOfWeek: Date? {
        let calendar = Calendar.current
        let componets = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)
        return calendar.date(from: componets)
    }
    /// 该时间所在周的最后一天日期
    var endOfWeek: Date? { startOfWeek?.ext.dateWith(day: 7, second: -1) }
    
    /// 返回当前时间，往前指定条数日期
    /// - Parameter count: > 0 往后 | < 0 往前
    func dates(_ count: Int) -> [Date] {
        var items = [Date]()
        items.append(base)
        let sign = count > 0 ? 1 : -1
        for i in 1..<abs(count) {
            items.append(dateWith(day: sign * i))
        }
        return items
    }
}
