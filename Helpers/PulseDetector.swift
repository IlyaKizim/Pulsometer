//
//  PulseDetector.swift
//  Pulsometer
//
//  Created by Кизим Илья on 16.04.2024.
//

import AVFoundation

private let maxPeriodsToStore = 20
private let averageSize = 20
private let invalidPulsePeriod = -1
private let maxPeriod = 1.5
private let minPeriod = 0.1
private let invalidEntry: Double = -100

final class PulseDetector: NSObject {
    
    //MARK: - Properties
    
    private var upVals = [Double](repeating: 0.0, count: averageSize)
    private var downVals = [Double](repeating: 0.0, count: averageSize)
    private var upValIndex = 0
    private var downValIndex = 0
    private var lastVal: Float = 0.0
    private var periods = [Double](repeating: 0.0, count: maxPeriodsToStore)
    private var periodTimes = [Double](repeating: 0.0, count: maxPeriodsToStore)
    private var periodIndex = 0
    private var started = false
    private var freq: Float = 0.0
    private var average: Float = 0.0
    private var wasDown = false
    private var periodStart: Double = 0.0
    
    //MARK: - Initializer
    
    override init() {
        super.init()
        reset()
    }
    
    //Add new value to the detector
    //Функция добавляет новое значение измеренной интенсивности света в детектор пульса, определяется момент перехода от уровня нижнего порога к уровню выше, что может указывать на наличие пика пульса.
    
    func addNewValue(newVal: Double, atTime time: Double) -> Float {
        // If the value is positive, store it in the upVals array
        // Если значение положительное, сохраняем его в массиве upVals
        if newVal > 0 {
            upVals[upValIndex] = newVal
            upValIndex += 1
            if upValIndex >= averageSize {
                upValIndex = 0
            }
        }
        // If the value is negative, store its in the downVals array
        // Если значение отрицательное, сохраняем его в массиве downVals
        if newVal < 0 {
            downVals[downValIndex] = -newVal
            downValIndex += 1
            if downValIndex >= averageSize {
                downValIndex = 0
            }
        }
        // Calculate the average value of positive values stored in upVals array
        // Вычисляем среднее значение положительных значений, хранящихся в массиве upVals
        var count: Double = 0
        var total: Double = 0
        for i in 0..<averageSize {
            if upVals[i] != invalidEntry {
                count += 1
                total += upVals[i]
            }
        }
        
        let averageUp: Double = total/count
        // Calculate the average value of negative, stored in downVals array
        // Вычисляем среднее значение отрицательных, хранящихся в массиве downVals
        count = 0
        total = 0
        for i in 0..<averageSize {
            if downVals[i] != invalidEntry {
                count += 1
                total += downVals[i]
            }
        }
        let averageDown: Double = total/count
        
        // Determine if the new value indicates a downward trend based on the calculated average value below zero
        // Определяем, указывает ли новое значение на нисходящий тренд на основе вычисленного среднего значения ниже нуля
        if newVal < -0.5 * averageDown {
            wasDown = true
        }
        // Check if the new value is an upward trend and whether we were previously in a downward state
        // Проверяем, является ли новое значение восходящим трендом и были ли мы ранее в состоянии нисходящего тренда
        if newVal >= 0.5 * averageUp && wasDown {
            wasDown = false
            // Calculate the difference between now and the last time this happened
            // Вычисляем разницу между текущим временем и последним разом, когда это произошло
            if time - periodStart < maxPeriod && time - periodStart > minPeriod {
                periods[periodIndex] = time - periodStart
                periodTimes[periodIndex] = time
                periodIndex += 1
                if periodIndex >= maxPeriodsToStore {
                    periodIndex = 0
                }
            }
            // Track when the transition happened
            // Отслеживаем, когда произошел переход
            periodStart = time
        }
        // Return -1 if the new value indicates a downward trend, 1 if it indicates an upward trend, or 0 otherwise
        // Возвращаем -1, если новое значение указывает на нисходящий тренд, 1, если оно указывает на восходящий тренд, или 0 в противном случае
        if newVal < -0.5 * averageDown {
            return -1
        } else if newVal > 0.5 * averageUp {
            return 1
        }
        return 0
    }

    func getAverage() -> Float {
        // Get the current time using CACurrentMediaTime()
        // Получаем текущее время с помощью CACurrentMediaTime()
        let time = CACurrentMediaTime()
        
        // Initialize variables to calculate the total and count of valid periods
        // Инициализируем переменные для вычисления общего и количества действительных периодов
        var total: Double = 0
        var count: Double = 0
        
        // Iterate through the periods array and check if the period is valid and within the last 10 seconds
        // Проходим по массиву периодов и проверяем, является ли период действительным и находится ли он в последние 10 секунд
        for i in 0..<maxPeriodsToStore {
            if periods[i] != invalidEntry && time - periodTimes[i] < 10 {
                count += 1
                total += periods[i]
            }
        }
        // Check if there are enough valid values to calculate the average
        // Проверяем, достаточно ли действительных значений для вычисления среднего
        if count > 2 {
            return Float(total / count)
        }
        // Return an invalid pulse period if there are not enough valid values
        // Возвращаем недопустимый период пульса, если недостаточно действительных значений
        return Float(invalidPulsePeriod)
    }

    func reset() {
        // Reset the periods array to invalidEntry for all elements
        // Сбрасываем массив периодов к значению invalidEntry для всех элементов
        for i in 0..<maxPeriodsToStore {
            periods[i] = invalidEntry
        }
        // Reset the upVals and downVals arrays to invalidEntry for all elements
        // Сбрасываем массивы upVals и downVals к значению invalidEntry для всех элементов
        for i in 0..<averageSize {
            upVals[i] = invalidEntry
            downVals[i] = invalidEntry
        }
        // Reset the frequency, periodIndex, downValIndex, and upValIndex
        // Сбрасываем частоту, индекс периода, индекс значения вниз и индекс значения вверх
        freq = 0.5
        periodIndex = 0
        downValIndex = 0
        upValIndex = 0
    }
}
