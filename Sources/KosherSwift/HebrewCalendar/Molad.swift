//
//  Molad.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/26/23.
//

import Foundation

public class MoladDate: JewishDate {
    public let molad: Molad
    
    init(fromMolad molad: Double) {
        self.molad = MoladDate.moladFromChalakim(chalakim: molad)
        let absDate = JewishDate.moladToAbsDate(chalakim: molad)
        
        super.init(date: JewishDate.absDateToDate(absDate: absDate))
    }
    
    init(chalakim: Double, date: Date) {
        self.molad = MoladDate.moladFromChalakim(chalakim: chalakim)
        super.init(date: date, includeTime: true)
    }
    
    convenience init(date: Date, hour: Int, minute: Int, chalakim: Int) {
        let molad = Molad(hours: hour, minutes: minute, chalakim: chalakim)
        self.init(date: date, molad: molad)
    }
    
    init(date: Date, molad: Molad) {
        self.molad = molad
        super.init(date: date, includeTime: true)
    }
    
    func withMoladHours(_ hours: Int) -> MoladDate {
        MoladDate(date: gregDate, hour: hours, minute: molad.minutes, chalakim: molad.chalakim)
    }
    
    static func calculate(forJewishDate jewishDate: JewishDate) -> MoladDate? {
        let m = getChalakimSinceMoladTohu(year: jewishDate.year, month: jewishDate.month)
        
        let absM = moladToAbsDate(chalakim: m)
        
        let temp = moladFromChalakim(chalakim: m)
        // Molad hours are counted from 6 PM of the previous evening; convert to clock hours and move to the next civil day if needed
        let hours = (temp.hours + 18) % 24
        let retMolad = Molad(hours: hours, minutes: temp.minutes, chalakim: temp.chalakim)
        let civilDate = absDateToGregorian(absDate: temp.hours >= 6 ? absM + 1 : absM)
        
        guard let dt = getMoladAsDate(retMolad, year: civilDate.year, month: civilDate.month, day: civilDate.day) else { return nil }
        
        return MoladDate(date: dt, molad: retMolad)
    }
    
    private static func moladFromChalakim(chalakim: Double) -> Molad {
        let conjunctionDay = chalakim ~/ JewishCalendar.chalakimPerDay
        var adjustedChalakim = (chalakim - Double(conjunctionDay) * Double(chalakimPerDay))
        
        let hours = adjustedChalakim ~/ chalakimPerHour
        adjustedChalakim = adjustedChalakim - (Double(hours) * Double(chalakimPerHour))
        let minutes = adjustedChalakim ~/ chalakimPerMinute
        let chalakim = adjustedChalakim - Double(minutes * chalakimPerMinute)
        
        return Molad(hours: hours, minutes: minutes, chalakim: Int(chalakim))
    }
    
    
    /// Converts a molad (already in clock hours) on a civil date to a point in time.
    ///
    /// The molad is in Jerusalem local mean time. As in KosherJava, the date is built in Jerusalem *standard* time
    /// (GMT+2, never DST) and then shifted by the local mean time offset of Har Habayis (35.2354°E), 20 minutes and 56.496 seconds.
    static func getMoladAsDate(_ molad: Molad, year: Int, month: Int, day: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 2 * 3600)!
        let moladSeconds = Double(molad.chalakim) * 10 / 3
        let moladDay = DateComponents(year: year, month: month, day: day, hour: molad.hours, minute: molad.minutes, second: Int(moladSeconds), nanosecond: Int((moladSeconds - Double(Int(moladSeconds))) * 1_000_000_000))
        guard let localMeanTime = calendar.date(from: moladDay) else { return nil }
        
        let localMeanTimeOffset = 35.2354 * 4 * 60 - 2 * 3600 // seconds
        return localMeanTime.addingTimeInterval(-localMeanTimeOffset)
    }
}

public struct Molad {
    public let hours: Int
    public let minutes: Int
    public let chalakim: Int
}
