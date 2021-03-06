//
//  Game.swift
//  Kulki
//
//  Created by Rafal Grodzinski on 24/04/16.
//  Copyright © 2016 UnalignedByte. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif


open class Game: NSObject
{
    #if os(iOS)
    internal(set) var view: UIView!
    #else
    internal(set) var view: NSView!
    #endif
    internal var field: Field
    internal var drawnMarbleColors: [Int]?
    internal weak var currentState: State?
    private var states: [State]!
    private var resumeState: State!


    // State data
    fileprivate var isWaitingForMove = false
    fileprivate weak var selectedMarble: Marble?
    fileprivate var spawnedMarbles: NSHashTable<Marble>?

    // Callbacks
    open var pauseCallback: (() -> Void)?
    open var quitCallback: (() -> Void)?

    // MARK: - Initialization -
    init(field: Field)
    {
        self.field = field
        super.init()
        
        self.setupView()
        assert(self.view != nil, "self.view must not be nil")

        // Setup states
        let startupState = State()
        startupState.command = { [weak self] (state: State) in self?.executeStartupState(state) }

        let spawnState = State()
        spawnState.command = { [weak self] (state: State) in self?.executeSpawnState(state) }

        let removeAfterSpawnState = State()
        removeAfterSpawnState.command = { [weak self] (state: State) in self?.executeRemoveAfterSpawnState(state) }

        let checkIfFinishedState = State()
        checkIfFinishedState.command = { [weak self] (state: State) in self?.executeCheckIfFinishedState(state) }

        let moveState = State()
        moveState.command = { [weak self] (state: State) in self?.executeMoveState(state) }
        resumeState = moveState

        let removeAfterMoveState = State()
        removeAfterMoveState.command = { [weak self] (state: State) in self?.executeRemoveAfterMoveState(state) }

        let finishedState = State()
        finishedState.command = { [weak self] (state: State) in self?.executeFinishedState(state) }

        // Startup -> Spawn
        startupState.nextState = spawnState
        // Spawn -> Remove after spawn
        spawnState.nextState = removeAfterSpawnState
        // Remove after spawn -> Check if finished
        removeAfterSpawnState.nextState = checkIfFinishedState
        // Check if finished -> Wait for move (or finished)
        checkIfFinishedState.nextState = moveState
        // Moving -> Remove after move
        moveState.nextState = removeAfterMoveState
        // Remove after move  -> Spawn
        removeAfterMoveState.nextState = spawnState

        self.states = [startupState, spawnState, removeAfterSpawnState, checkIfFinishedState,
                       moveState, removeAfterMoveState, finishedState]
    }


    // MARK: <<Abstract>>
    internal func setupView()
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: <<Abstract>>
    internal func setupCustom()
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: - Control -
    open func startGame()
    {
        // Setup score singleton
        ScoreSingleton.sharedInstance.newGameWithColorsCount(self.field.colorsCount, lineLength: self.field.lineLength)
        // Reset the field (in case the game was restarted)
        self.field.reset()

        // Load all the objects
        self.setupCustom()

        self.states[0].execute()
    }

    func resumeGame()
    {
        // Load all the objects
        self.setupCustom()
        let marbles = self.field.marbles.map {  $0.value }
        self.showBoard({})
        self.showMarbles(marbles, nextMarbleColors: self.drawnMarbleColors!, finished: {})

        self.resumeState.execute()
    }


    // MARK: - State -
    func executeStartupState(_ state: State)
    {
        self.currentState = state

        self.drawnMarbleColors = self.field.drawNextMarbleColors()
        self.showBoard(state.goToNextState)
    }


    func executeSpawnState(_ state: State)
    {
        self.currentState = state

        self.spawnedMarbles = NSHashTable<Marble>(options: .weakMemory)
        let spawned = self.field.spawnMarbles(self.drawnMarbleColors!)
        for marble in spawned {
            self.spawnedMarbles?.add(marble)
        }

        self.drawnMarbleColors = self.field.drawNextMarbleColors()
        self.showMarbles(spawned, nextMarbleColors: self.drawnMarbleColors!, finished: state.goToNextState)
    }


    func executeRemoveAfterSpawnState(_ state: State)
    {
        self.currentState = state

        var removedMarbles = [Marble]()

        for marble in self.spawnedMarbles!.allObjects {
            let lineOfMarbles = self.field.removeLinesAtMarble(marble)
            removedMarbles.append(contentsOf: lineOfMarbles)

            ScoreSingleton.sharedInstance.removedMarbles(lineOfMarbles.count)
        }

        if removedMarbles.count > 0 {
            self.hideMarbles(removedMarbles, finished: state.goToNextState)
            self.updateScore(ScoreSingleton.sharedInstance.currentScore)
        } else {
            state.goToNextState()
        }
    }


    func executeCheckIfFinishedState(_ state: State)
    {
        self.currentState = state

        if self.field.isFull {
            let finishedState = self.states.last!
            finishedState.execute()
        } else {
            state.goToNextState()
        }
    }


    func executeMoveState(_ state: State)
    {
        self.currentState = state
        self.selectedMarble = nil

        if self.field.isEmpty {
            self.currentState?.goToNextState()
        } else {
            self.isWaitingForMove = true
        }
    }


    func executeRemoveAfterMoveState(_ state: State)
    {
        let removedMarbles = self.field.removeLinesAtMarble(self.selectedMarble)
        self.selectedMarble = nil

        ScoreSingleton.sharedInstance.removedMarbles(removedMarbles.count)

        if removedMarbles.count > 0 {
            // get move state
            let currentStateIndex = self.states.index(of: state)
            let moveState = self.states[currentStateIndex!.advanced(by: -1)]

            self.hideMarbles(removedMarbles, finished: moveState.execute)
            self.updateScore(ScoreSingleton.sharedInstance.currentScore)
        } else {
            state.goToNextState()
        }
    }


    func executeFinishedState(_ state: State)
    {
        self.currentState = state

        let score = ScoreSingleton.sharedInstance.currentScore
        let isHighScore = ScoreSingleton.sharedInstance.currentScore > ScoreSingleton.sharedInstance.highScore
        if isHighScore {
            ScoreSingleton.sharedInstance.highScore = score
        }

        self.gameFinished(score, isHighScore: isHighScore)
    }


    // MARK: - Startup -

    // MARK: <<Abstract>>
    func showBoard(_ finished: @escaping () -> Void)
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: - Spawn -

    // MARK: <<Abstract>>
    func showMarbles(_ marbles: [Marble], nextMarbleColors: [Int], finished: @escaping () -> Void)
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: - Remove -

    // MARK: <<Abstract>>
    func hideMarbles(_ marbles: [Marble], finished: @escaping () -> Void)
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: <<Abstract>>
    func updateScore(_ newScore: Int)
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: - Move -
    func tappedFieldPosition(_ fieldPosition: Point)
    {
        if !self.isWaitingForMove {
            return
        }

        // Are we trying to select a marble?
        if let marble = self.field.marbles[fieldPosition] {
            // Ignore if already selected
            if marble === self.selectedMarble {
                return
            }

            // Deselect currently selected marble
            if let selectedMarble = self.selectedMarble {
                self.deselectMarble(selectedMarble)
            }

            self.selectedMarble = marble
            self.selectMarble(marble)
        // Otherwise, might be trying to move a marble
        } else if let selectedMarble = self.selectedMarble {
            if let path = self.field.moveMarble(selectedMarble, toPosition: fieldPosition) {
                self.isWaitingForMove = false
                self.deselectMarble(selectedMarble)
                self.moveMarble(selectedMarble, overFieldPath: path, finished: self.currentState!.goToNextState)
            }
        }
    }


    // MARK: <<Abstract>>
    func selectMarble(_ marbe: Marble)
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: <<Abstract>>
    func deselectMarble(_ marbe: Marble)
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: <<Abstract>>
    func moveMarble(_ marble: Marble, overFieldPath fieldPath: [Point], finished: @escaping () -> Void)
    {
        assert(false, "<<Abstract method>>")
    }


    // MARK: - Finished -

    // MARK: <<Abstract>>
    func gameFinished(_ score: Int, isHighScore: Bool)
    {
        assert(false, "<<Abstract method>>")
    }
}
