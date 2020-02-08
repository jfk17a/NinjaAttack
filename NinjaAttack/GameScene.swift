/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit

struct PhysicsCategory {
  static let none      : UInt32 = 0
  static let all       : UInt32 = UInt32.max
  static let monster   : UInt32 = 0b1
  static let projectile: UInt32 = 0b10
}


func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

class GameScene: SKScene {
  
  let player = SKSpriteNode(imageNamed: "player")
  var scoreLabel: SKLabelNode!
  var score = 0 {
    didSet{
      scoreLabel.text = "Score: \(score)"
    }
  }
  var monsterLabel: SKLabelNode!
  var monstersDestroyed = 0
//  {
//    didSet{
//      monsterLabel.text = "Monsters Killed: \(monstersDestroyed)"
//    }
//  }

    
  override func didMove(to view: SKView) {
    backgroundColor = SKColor.green
    
//    monsterLabel = SKLabelNode(fontNamed: "Chalkduster")
//    monsterLabel.text = "Monsters Killed: 0"
//    monsterLabel.horizontalAlignmentMode = .left
//    monsterLabel.position = CGPoint(x: 20, y: 365)
//    addChild(monsterLabel)
    
    scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    scoreLabel.text = "Score: 0"
    scoreLabel.horizontalAlignmentMode = .left
    scoreLabel.position = CGPoint(x: 20, y: 365/*320*/)
    addChild(scoreLabel)
    
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    addChild(player)
    
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    
    let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf.caf")
    backgroundMusic.autoplayLooped = true
    addChild(backgroundMusic)
    
    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addTrees),
        SKAction.wait(forDuration: Double.random(in: 1...3))
        ])
    ))
    
    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addMonster),
        SKAction.wait(forDuration: 1.0)
        ])
    ))
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }

  func addMonster() {
    
    var randoMonster = Int.random(in: 1...3)
    
    
    // Create sprite
    let ghost = SKSpriteNode(imageNamed: "monster\(randoMonster)")
    
    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: ghost.size.height/2, max: size.height - ghost.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    ghost.position = CGPoint(x: size.width + ghost.size.width/2, y: actualY)
    
    // Add the monster to the scene
    addChild(ghost)
    
    // Determine speed of the monster
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    // Create the actions
    let actionMove = SKAction.move(to: CGPoint(x: -ghost.size.width/2, y: actualY),
                                   duration: TimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
    
    let loseAction = SKAction.run() { [weak self] in
      guard let `self` = self else { return }
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    ghost.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))

    
    ghost.physicsBody = SKPhysicsBody(rectangleOf: ghost.size) // 1
    ghost.physicsBody?.isDynamic = true // 2
    ghost.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3
    ghost.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
    ghost.physicsBody?.collisionBitMask = PhysicsCategory.none // 5

  }
  
  func addTrees() {
    
    var randoTree = Int.random(in: 1...3)
    
    
    // Create sprite
    let tree = SKSpriteNode(imageNamed: "tree\(randoTree)")
    
    // Determine where to spawn the Tree along the Y axis
    let actualY = random(min: tree.size.height/2, max: size.height - tree.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    tree.position = CGPoint(x: size.width + tree.size.width/2, y: actualY)
    
    // Add the monster to the scene
    addChild(tree)
    
    // Determine speed of the monster
    let actualDuration = 5
    
    // Create the actions
    let actionMove = SKAction.move(to: CGPoint(x: -tree.size.width/2, y: actualY),
                                   duration: TimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
    
    let loseAction = SKAction.run() {
    }
    
    tree.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))

  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // Choose one of the touches to work with
    guard let touch = touches.first else {
      return
    }
    
    run(SKAction.playSoundFileNamed("egg_throw.caf", waitForCompletion: false))
    
    let touchLocation = touch.location(in: self)
    
    // Set up initial location of projectile
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
    
    // Determine offset of location to projectile
    let offset = touchLocation - projectile.position
    
    // Bail out if you are shooting down or backwards
    if offset.x < 0 { return }
    
    // OK to add now - you've double checked position
    addChild(projectile)
    
    // Get the direction of where to shoot
    let direction = offset.normalized()
    
    // Make it shoot far enough to be guaranteed off screen
    let shootAmount = direction * 1000
    
    // Add the shoot amount to the current position
    let realDest = shootAmount + projectile.position
    
    // Create the actions
    let actionMove = SKAction.move(to: realDest, duration: 2.0)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
    projectile.physicsBody?.usesPreciseCollisionDetection = true

  }
  
  func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
    run(SKAction.playSoundFileNamed("egg_splat.caf", waitForCompletion: false))
    print("Hit")
    projectile.removeFromParent()
    monster.removeFromParent()
    score += 1
    monstersDestroyed += 1
    if monstersDestroyed == 10{
      for _ in 1...10{
        addMonster()
      }
    }
    if monstersDestroyed > 25{
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: true)
      view?.presentScene(gameOverScene, transition: reveal)
    }
  }
}

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
   
    if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
        (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
      if let monster = firstBody.node as? SKSpriteNode,
        let projectile = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithMonster(projectile: projectile, monster: monster)
      }
    }
  }

}
