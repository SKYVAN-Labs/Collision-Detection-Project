//
//  GameScene.swift
//  AdvanceSpriteKitButtonProject
//
//  Created by Skyler Lauren on 9/2/17.
//  Copyright © 2017 SkyVan Labs. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SVLSpriteNodeButtonDelegate, SKPhysicsContactDelegate {
    
    var shipCategory: UInt32 = 1
    var asteroidCategory: UInt32 = 2
    var bulletCategory: UInt32 = 4
    
    var leftArrowButton: SVLSpriteNodeButton!
    var rightArrowButton: SVLSpriteNodeButton!
    var shootButton: SVLSpriteNodeButton!
    
    var ship: SKSpriteNode!

    var lastUpdateTime: TimeInterval = 0
    var shipSpeed: CGFloat = 10.0
    
    //random logic
    var delay: TimeInterval = 0.5
    var timeSinceStart: TimeInterval = 0.0
    
    //MARK: - Scene Stuff
    override func didMove(to view: SKView) {
        
        leftArrowButton = childNode(withName: "leftArrowButton") as! SVLSpriteNodeButton
        
        rightArrowButton = childNode(withName: "rightArrowButton") as! SVLSpriteNodeButton
        
        shootButton = childNode(withName: "shootButton") as! SVLSpriteNodeButton
        shootButton.delegate = self
        
        ship = childNode(withName: "ship") as! SKSpriteNode
        shipSpeed = size.width/2.0
        asteroidSpawner(delay: 0.5)
        
        physicsWorld.contactDelegate = self
    }
    
    func asteroidSpawner(delay: TimeInterval){
        removeAction(forKey: "spawnAsteroids")
        
        self.delay = delay
        
        let delayAction = SKAction.wait(forDuration: delay)
        let spawnAction = SKAction.run {
            self.spawnAsteroid()
        }
        
        let sequenceAction = SKAction.sequence([delayAction, spawnAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        
        run(repeatAction, withKey: "spawnAsteroids")
    }
    
    func spawnAsteroid(){
        
        //size
        var asteroidSize = CGSize(width: 50, height: 50)
        
        let randomSize = arc4random() % 3
        
        switch randomSize {
        case 1:
            asteroidSize.width *= 1.2
            asteroidSize.height *= 1.2
        case 2:
            asteroidSize.width *= 1.5
            asteroidSize.height *= 1.5
        default:
            break
        }
        
        //position
        let y = size.height/2+asteroidSize.height/2
        
        var randomX = CGFloat(arc4random() % UInt32(size.width-asteroidSize.width))
        randomX -= size.width/2-asteroidSize.width/2
        
        //init
        let asteroid = SKSpriteNode(color: SKColor.brown, size: asteroidSize)
        asteroid.position = CGPoint(x: randomX, y: y)
        addChild(asteroid)
        
        //physics
        asteroid.physicsBody = SKPhysicsBody(rectangleOf: asteroidSize)
        asteroid.physicsBody?.affectedByGravity = false
        asteroid.physicsBody?.allowsRotation = false
        
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.collisionBitMask = 0
        asteroid.physicsBody?.contactTestBitMask = shipCategory

        //move
        let moveDownAction = SKAction.moveBy(x: 0, y: -size.height-asteroid.size.height, duration: 2.0)
        let destroyAction = SKAction.removeFromParent()
        let sequenceAction = SKAction.sequence([moveDownAction, destroyAction])
        asteroid.run(sequenceAction)
        
        //rotation
        var rotateAction = SKAction.rotate(byAngle: 1, duration: 1)
        
        let randomRotation = arc4random() % 2
        
        if randomRotation == 1  {
            rotateAction = SKAction.rotate(byAngle: -1, duration: 1)
        }
        
        let repeatForeverAction = SKAction.repeatForever(rotateAction)
        asteroid.run(repeatForeverAction)
    }
    
    override func update(_ currentTime: TimeInterval) {

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        let dt = currentTime - lastUpdateTime
        
        if leftArrowButton.state == .down{
            ship.position.x -= shipSpeed * CGFloat(dt)
        }
        
        if ship.position.x < -size.width/2+ship.size.width/2{
            ship.position.x = -size.width/2+ship.size.width/2
        }
        
        if rightArrowButton.state == .down{
            ship.position.x += shipSpeed * CGFloat(dt)
        }
        
        if ship.position.x > size.width/2-ship.size.width/2{
            ship.position.x = size.width/2-ship.size.width/2
        }
        
        //difficulty
        timeSinceStart += dt

        if timeSinceStart > 5 && delay > 0.4 {
            asteroidSpawner(delay: 0.4)
        } else if timeSinceStart > 10 && delay > 0.3 {
            asteroidSpawner(delay: 0.1)
        }
        
        lastUpdateTime = currentTime
    }
    
    func shoot(){
        
        if ship.parent == nil {
            return
        }
        
        let bullet = SKSpriteNode(color: SKColor.red, size: CGSize(width: 10, height: 20))
        bullet.position = ship.position
        bullet.position.y += ship.size.height/2 + bullet.size.height/2
        addChild(bullet)
        
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.allowsRotation = false
        
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.contactTestBitMask = asteroidCategory
        
        let moveUpAction = SKAction.moveBy(x: 0, y: size.height, duration: 1.0)
        let destroy = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveUpAction, destroy])
        
        bullet.run(sequence)
    }
    
    //MARK: - SVLSpriteNodeButtonDelegate
    func spriteButtonDown(_ button: SVLSpriteNodeButton){
        print("spriteButtonDown")
    }
    
    func spriteButtonUp(_ button: SVLSpriteNodeButton){
        print("spriteButtonUp")
    }
    
    func spriteButtonMoved(_ button: SVLSpriteNodeButton){
        print("spriteButtonMoved")
    }
    
    func spriteButtonTapped(_ button: SVLSpriteNodeButton){
        if button == shootButton {
            shoot()
        }
    }
    
    //MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        print ("hit")
        
        //ship
        var ship: SKSpriteNode?
        
        if contact.bodyA.categoryBitMask == shipCategory {
            ship = contact.bodyA.node as? SKSpriteNode
        }else if contact.bodyB.categoryBitMask == shipCategory{
            ship = contact.bodyB.node as? SKSpriteNode
        }
        
        if ship != nil {
            print("ship hit")
            ship?.physicsBody = nil
            ship?.removeFromParent()
        }
        
        //bullet
        var bullet: SKSpriteNode?
        var other: SKNode?

        if contact.bodyA.categoryBitMask == bulletCategory {
            bullet = contact.bodyA.node as? SKSpriteNode
            other = contact.bodyB.node
        }else if contact.bodyB.categoryBitMask == bulletCategory{
            bullet = contact.bodyB.node as? SKSpriteNode
            other = contact.bodyA.node
        }
        
        if bullet != nil {
            print("asteroid hit")
            other?.physicsBody = nil
            other?.removeFromParent()
        }
        
    }
    
    
    
    
    
    
}
