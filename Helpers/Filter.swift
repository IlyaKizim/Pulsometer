//
//  Filter.swift
//  Pulsometer
//
//  Created by Кизим Илья on 16.04.2024.
//

import Foundation

private let numberOfZeros: Int = 10
private let numberOfPoles: Int = 10
private let gain: Double = 1.894427025e+01

final class Filter: NSObject {
    // Initialize arrays xv and yv with zeros
    // Инициализируем массивы xv и yv нулями
    var xv = [Double](repeating: 0.0, count: numberOfZeros + 1)
    var yv = [Double](repeating: 0.0, count: numberOfPoles + 1)

    // Process the input value using the filter
    // Обрабатываем входное значение с помощью фильтра
    func processValue(value: Double) -> Double {
        // Shift the values in array xv by one position to the right
        // Сдвигаем значения в массиве xv на одну позицию вправо
        xv[0] = xv[1]
        xv[1] = xv[2]
        xv[2] = xv[3]
        xv[3] = xv[4]
        xv[4] = xv[5]
        xv[5] = xv[6]
        xv[6] = xv[7]
        xv[7] = xv[8]
        xv[8] = xv[9]
        xv[9] = xv[10]
        xv[10] = value/gain
        
        // Shift the values in array yv by one position to the right
        // Сдвигаем значения в массиве yv на одну позицию вправо
        yv[0] = yv[1]
        yv[1] = yv[2]
        yv[2] = yv[3]
        yv[3] = yv[4]
        yv[4] = yv[5]
        yv[5] = yv[6]
        yv[6] = yv[7]
        yv[7] = yv[8]
        yv[8] = yv[9]
        yv[9] = yv[10]
        // Calculate the new value of yv[10] based on the filter equation
        // Вычисляем новое значение yv[10] на основе уравнения фильтра
        yv[10] = (xv[10] - xv[0]) + 5 * (xv[2] - xv[8]) + 10 * (xv[6] - xv[4]) + (-0.0000000000 * yv[0]) + (0.0357796363 * yv[1]) + (-0.1476158522 * yv[2]) + (0.3992561394 * yv[3]) + (-1.1743136181 * yv[4]) + (2.4692165842 * yv[5]) + (-3.3820859632 * yv[6]) + (3.9628972812 * yv[7]) + (-4.3832594900 * yv[8]) + (3.2101976096 * yv[9])
        // Return the new value of yv[10]
        // Возвращаем новое значение yv[10]
        return yv[10]
    }
}
