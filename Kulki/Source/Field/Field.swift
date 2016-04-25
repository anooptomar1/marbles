//
//  Field.swift
//  Kulki
//
//  Created by Rafal Grodzinski on 11/02/16.
//  Copyright © 2016 UnalignedByte. All rights reserved.
//

import UIKit


struct Point {
    var x: Int
    var y: Int
}


struct Size {
    var width: Int
    var height: Int

    init(_ width: Int, _ height: Int)
    {
        self.width = width
        self.height = height
    }
}


// This enables us to store CGPoint as a key in dictionary
extension CGPoint: Hashable
{
    public var hashValue: Int {
        return "\(x)\(y)".hash
    }
}


class Field
{
    var isFull: Bool {
        return self.balls.count >= self.width * self.height
    }

    private(set) var width: Int = 0
    private(set) var height: Int = 0
    private(set) var balls: [CGPoint : Int] = [:] //position and color

    private let size: Size
    private let colorsCount: Int
    private let marblesPerSpawn: Int
    private let lineLength: Int
    private let marbleFactory: MarbleFactory


    // MARK: - Initialization -
    init(size: Size, colorsCount: Int, marblesPerSpawn: Int, lineLength: Int, marbleFactory: MarbleFactory)
    {
        self.size = size
        self.colorsCount = colorsCount
        self.marblesPerSpawn = marblesPerSpawn
        self.lineLength = lineLength
        self.marbleFactory = marbleFactory
    }


    /*init(fieldSize: CGSize, colorsCount: Int)
    {
        self.width = Int(fieldSize.width)
        self.height = Int(fieldSize.height)
        self.balls = [CGPoint : Int]()
    }*/


    func moveBallFromPosition(from: CGPoint, toPosition to: CGPoint) -> [CGPoint]?
    {
        let path = self.findPathFromPosition(from, toPosition: to)

        // If found a path, move the ball in dictionary
        if path != nil {
            let ballColor = self.balls[from]
            self.balls.removeValueForKey(from)
            self.balls[to] = ballColor
        }

        return path
    }


    private func findPathFromPosition(from: CGPoint, toPosition to: CGPoint, visitedMap: [CGPoint: Bool]? = nil) -> [CGPoint]?
    {
        var map = visitedMap

        // Make sure the map is initialized
        if map == nil {
            map = [CGPoint: Bool]()
        }

        // Mask current cell as visited
        map![from] = true

        // Are we at the goal?
        if from == to {
            return [from]
        }

        // Check which directions can we move
        var hasUpExecuted = false
        var hasDownExecuted = false
        var hasLeftExecuted = false
        var hasRightExecuted = false

        var isInUpDirection = to.y > from.y
        var isInDownDirection = to.y < from.y
        var isInLeftDirection = to.x < from.x
        var isInRightDirection = to.x > from.x

        while true {
            // Up
            let isAtTopEdge = Int(from.y) >= self.height-1
            let isUpVisited = map![CGPointMake(from.x, from.y + 1)] == true
            let isUpOccupied = self.balls[CGPointMake(from.x, from.y + 1)] != nil

            let canMoveUp = !isAtTopEdge && !isUpVisited && !isUpOccupied

            if canMoveUp && isInUpDirection && !hasUpExecuted {
                var path = self.findPathFromPosition(CGPointMake(from.x, from.y+1), toPosition: to, visitedMap: map)

                // If path has been found, return it
                if path != nil {
                    path!.append(from)
                    return path
                }

                hasUpExecuted = true
            } else if !canMoveUp {
                hasUpExecuted = true
            }

            // Down
            let isAtBottomEdge = from.y <= 0
            let isDownVisited = map![CGPointMake(from.x, from.y - 1)] == true
            let isDownOccupied = self.balls[CGPointMake(from.x, from.y - 1)] != nil

            let canMoveDown = !isAtBottomEdge && !isDownVisited && !isDownOccupied

            if canMoveDown && isInDownDirection && !hasDownExecuted {
                var path = self.findPathFromPosition(CGPointMake(from.x, from.y-1), toPosition: to, visitedMap: map)

                // If path has been found, return it
                if path != nil {
                    path!.append(from)
                    return path
                }

                hasDownExecuted = true
            } else if !canMoveDown {
                hasDownExecuted = true
            }

            // Left
            let isAtLeftEdge = Int(from.x) <= 0
            let isLeftVisited = map![CGPointMake(from.x-1, from.y)] == true
            let isLeftOccupied = self.balls[CGPointMake(from.x-1, from.y)] != nil

            let canMoveLeft = !isAtLeftEdge && !isLeftVisited && !isLeftOccupied

            if canMoveLeft && isInLeftDirection && !hasLeftExecuted {
                var path = self.findPathFromPosition(CGPointMake(from.x-1, from.y), toPosition: to, visitedMap: map)

                // If path has been found, return it
                if path != nil {
                    path!.append(from)
                    return path
                }

                hasLeftExecuted = true
            } else if !canMoveLeft {
                hasLeftExecuted = true
            }

            // Right
            let isAtRightEdge = Int(from.x) >= self.width-1
            let isRightVisited = map![CGPointMake(from.x+1, from.y)] == true
            let isRightOccupied = self.balls[CGPointMake(from.x+1, from.y)] != nil

            let canMoveRight = !isAtRightEdge && !isRightVisited && !isRightOccupied

            if canMoveRight && isInRightDirection && !hasRightExecuted {
                var path = self.findPathFromPosition(CGPointMake(from.x+1, from.y), toPosition: to, visitedMap: map)

                // If path has been found, return it
                if path != nil {
                    path!.append(from)
                    return path
                }

                hasRightExecuted = true
            } else if !canMoveRight {
                hasRightExecuted = true
            }

            if isInUpDirection && isInDownDirection && isInLeftDirection && isInRightDirection {
                break
            } else {
                isInUpDirection = true
                isInDownDirection = true
                isInLeftDirection = true
                isInRightDirection = true
            }
        }

        // Nothing has been found, return nil
        return nil
    }


    func spawnBalls(count: Int, colorsCount: Int) -> [(CGPoint, Int)]
    {
        var spawnedBalls = [(CGPoint, Int)]()

        for _ in 0..<count {
            if self.isFull {
                break
            }

            while true {
                let x = random() % self.width
                let y = random() % self.height
                let position = CGPointMake(CGFloat(x), CGFloat(y))

                if self.balls[position] == nil {
                    let color = random() % colorsCount
                    self.balls[position] = color

                    spawnedBalls.append((position, color))
                    break
                }
            }
        }

        return spawnedBalls
    }


    func removeLinesAtPosition(position: CGPoint, lineLength: Int) -> [CGPoint]
    {
        var removedPositions = Set<CGPoint>()

        let color = self.balls[position]

        // Check horizontal extent
        var startX = Int(position.x)
        for x in (startX-1).stride(through: 0, by: -1) {
            let currentPosition = CGPointMake(CGFloat(x), position.y)
            let currentColor = self.balls[currentPosition]
            if currentColor == color {
                startX = x
            } else {
                break
            }
        }

        var endX = Int(position.x)
        for x in (startX+1).stride(through: self.width-1, by: 1) {
            let currentPosition = CGPointMake(CGFloat(x), position.y)
            let currentColor = self.balls[currentPosition]
            if currentColor == color {
                endX = x
            } else {
                break
            }
        }

        // Check vertial extent
        var startY = Int(position.y)
        for y in (startY-1).stride(through: 0, by: -1) {
            let currentPosition = CGPointMake(position.x, CGFloat(y))
            let currentColor = self.balls[currentPosition]
            if currentColor == color {
                startY = y
            } else {
                break
            }
        }

        var endY = Int(position.y)
        for y in (startY+1).stride(through: self.height-1, by: 1) {
            let currentPosition = CGPointMake(position.x, CGFloat(y))
            let currentColor = self.balls[currentPosition]
            if currentColor == color {
                endY = y
            } else {
                break
            }
        }

        // Check if there is a horizontal line to be removed
        if endX - startX >= lineLength-1 {
            for x in startX...endX {
                removedPositions.insert(CGPointMake(CGFloat(x), position.y))
            }
        }

        // Check if there is a vertical line to be removed
        if endY - startY >= lineLength-1 {
            for y in startY...endY {
                removedPositions.insert(CGPointMake(position.x, CGFloat(y)))
            }
        }

        // Remove all the relevant balls from the dictionary
        for position in removedPositions {
            self.balls.removeValueForKey(position)
        }

        return removedPositions.map() { $0 }
    }
}