//
//  ViewController.swift
//  Glider
//
//  Created by Tamas Bara on 12.01.17.
//  Copyright © 2017 Tamas Bara. All rights reserved.
//

import UIKit

enum SwipeDirection {
    case left
    case right
    case none
}

class SwipeableElement {
    var view: UIImageView?
    var originalCenter: CGPoint!
    var isPlaceholder = false
    var image: String?
    
    init(image: String, frame: CGRect) {
        view = UIImageView(image: UIImage(named: image))
        view!.contentMode = .scaleAspectFit
        view!.frame = frame
        originalCenter = view!.center
        self.image = image
    }
    
    init() {
        isPlaceholder = true
    }
    
    func moveToOriginalPosition() {
        if !isPlaceholder {
            view!.center = CGPoint(x: originalCenter.x, y: view!.center.y)
        }
    }
    
    func moveLeft(offsetIncrement: CGFloat) {
        if !isPlaceholder {
            view!.center = CGPoint(x: originalCenter.x - offsetIncrement, y: view!.center.y)
            originalCenter = view!.center
        }
    }
    
    func moveRight(offsetIncrement: CGFloat) {
        if !isPlaceholder {
            view!.center = CGPoint(x: originalCenter.x + offsetIncrement, y: view!.center.y)
            originalCenter = view!.center
        }
    }
    
    func moveOriginalCenterLeft(offsetIncrement: CGFloat) {
        if !isPlaceholder {
            originalCenter = CGPoint(x: originalCenter.x - offsetIncrement, y: view!.center.y)
        }
    }
    
    func moveOriginalCenterRight(offsetIncrement: CGFloat) {
        if !isPlaceholder {
            originalCenter = CGPoint(x: originalCenter.x + offsetIncrement, y: view!.center.y)
        }
    }
}

class ViewController: UIViewController, UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate {
    var images = ["snap1", "snap2", "snap3", "snap4", "snap5"]
    var stack = [SwipeableElement]()
    var swipeables = [SwipeableElement]()
    
    var previousTouchPoint: CGPoint!
    var firstTouchPoint: CGPoint!
    
    var animator: UIDynamicAnimator!
    var swipeDirection = SwipeDirection.none
    
    let minDistance = CGFloat(50)
    var snapFinished = false
    
    var width: CGFloat!
    var height: CGFloat!
    var center: CGPoint!
    var offsetIncrement: CGFloat!
    
    var panRecog: UIPanGestureRecognizer!
    
    var selected: SwipeableElement!
    var selectedLeftNeighbour: SwipeableElement!
    var selectedRightNeighbour: SwipeableElement!
    
    var innerMode = false
    var animating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screen = UIScreen.main.bounds
        width = screen.width - 100
        height = screen.height - 100
        center = CGPoint(x: screen.width / 2, y: screen.height / 2)
        
        let xPos = center.x - width / 2
        let yPos = center.y - height / 2
        let frame = CGRect(x: xPos, y: yPos, width: width, height: height)
        
        selected = SwipeableElement(image: images[2], frame: frame)
        
        let recog = UITapGestureRecognizer(target: self, action: #selector(ViewController.tap))
        view.addGestureRecognizer(recog)
        view.addSubview(selected.view!)
        
        let scaleFactor = screen.width / selected.view!.bounds.size.width
        selected.view!.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        
        animator = UIDynamicAnimator(referenceView: view)
        animator.delegate = self
    }
    
    func tap(recog: UIPanGestureRecognizer) {
        if innerMode {
            showSelected()
        } else {
            if !animating {
                animating = true
                innerMode = true
                self.createGlider()
                UIView.animate(withDuration: 0.5, animations: {
                    self.selected.view!.transform = .identity
                    self.swipeables[1].view!.alpha = 1
                    self.swipeables[3].view!.alpha = 1
                    self.view.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
                }, completion: { finished in
                    self.animating = false
                })
            }
        }
    }
    
    func showSelected() {
        innerMode = false
        print("animator is running: \(animator.isRunning)")
        view.bringSubview(toFront: selected.view!)
        
        view.removeGestureRecognizer(panRecog)
        
        let toShow = SwipeableElement(image: selected.image!, frame: selected.view!.frame)
        view.addSubview(toShow.view!)
        selected = toShow
        
        if animator.isRunning {
            swipeDirection = .none
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            let screen = UIScreen.main.bounds
            let scaleFactor = screen.width / toShow.view!.bounds.size.width
            toShow.view!.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            
            if !self.selectedLeftNeighbour.isPlaceholder {
                self.selectedLeftNeighbour.view!.alpha = 0
            }
            
            if !self.selectedRightNeighbour.isPlaceholder {
                self.selectedRightNeighbour.view!.alpha = 0
            }
            
            self.view.backgroundColor = UIColor.white
        }, completion: { finished in
            for swipeable in self.swipeables {
                if !swipeable.isPlaceholder {
                    swipeable.view!.removeFromSuperview()
                }
            }
            
            self.swipeables.removeAll()
            
            for swipeable in self.stack {
                if !swipeable.isPlaceholder {
                    swipeable.view!.removeFromSuperview()
                }
            }
            
            self.stack.removeAll()
        })
    }
    
    func createGlider() {
        let xPos = center.x - width / 2
        let yPos = center.y - height / 2
        offsetIncrement = width + 20
        
        var modifiedImages = [String]()
        for image in images {
            if image != selected.image! {
                modifiedImages.append(image)
            }
        }
        
        modifiedImages.insert(selected.image!, at: 2)
        
        var offset = -2 * offsetIncrement
        for index in 0...4 {
            if index == 2 {
                swipeables.append(selected)
            } else {
                let frame = CGRect(x: xPos + offset, y: yPos, width: width, height: height)
                let elem = SwipeableElement(image: modifiedImages[index], frame:frame)
                view.addSubview(elem.view!)
                swipeables.append(elem)
                if index == 1 || index == 3 {
                    elem.view!.alpha = 0
                    if index == 1 {
                        selectedLeftNeighbour = elem
                    } else {
                        selectedRightNeighbour = elem
                    }
                }
            }
            
            offset += offsetIncrement
        }
        
        panRecog = UIPanGestureRecognizer(target: self, action: #selector(ViewController.pan))
        view.addGestureRecognizer(panRecog)
    }
    
    func pan(recog: UIPanGestureRecognizer) {
        let touchPoint = recog.location(in: self.view)
        
        if recog.state == .began {
            previousTouchPoint = touchPoint
            firstTouchPoint = touchPoint
            animator.removeAllBehaviors()
            snapFinished = false
        } else if recog.state == .changed {
            let xOffset = previousTouchPoint.x - touchPoint.x
            
            for elem in swipeables {
                if !elem.isPlaceholder {
                    elem.view!.center = CGPoint(x: elem.view!.center.x - xOffset, y: elem.view!.center.y)
                }
            }
            
            previousTouchPoint = touchPoint
            if xOffset > 0 {
                swipeDirection = .left
            } else {
                swipeDirection = .right
            }
        } else if recog.state == .ended {
            if !snapFinished {
                snapFinished = true
                var distance = touchPoint.x - firstTouchPoint.x
                if distance < 0 {
                    distance *= -1
                }
                
                snap(distance: distance)
            }
        }
    }

    func snap(distance: CGFloat) {
        var snapIndex = 1
        if swipeDirection == .left {
            snapIndex = 3
        }
        
        let elemToSnap = swipeables[snapIndex]
        var viewToSnap: UIView?
        if (elemToSnap.isPlaceholder || distance < minDistance) {
            snapIndex = 2
            viewToSnap = swipeables[2].view
            swipeDirection = .none
        } else {
            viewToSnap = swipeables[snapIndex].view
            view.bringSubview(toFront: viewToSnap!)
        }
        
        let snapIndexLeftNeighbour = snapIndex - 1
        let snapIndexRightNeighbour = snapIndex + 1
        
        selected = swipeables[snapIndex]
        selectedLeftNeighbour = swipeables[snapIndexLeftNeighbour]
        selectedRightNeighbour = swipeables[snapIndexRightNeighbour]
        
        animating = true
        
        var index = 0
        for swipeable in swipeables {
            if !swipeable.isPlaceholder {
                if index >= snapIndexLeftNeighbour && index <= snapIndexRightNeighbour {
                    var snapTo = CGPoint(x: swipeable.originalCenter.x, y: swipeable.view!.center.y)
                    if self.swipeDirection == .left {
                        snapTo = CGPoint(x: swipeable.originalCenter.x - offsetIncrement, y: swipeable.view!.center.y)
                        swipeable.moveOriginalCenterLeft(offsetIncrement: offsetIncrement)
                    } else if self.swipeDirection == .right {
                        snapTo = CGPoint(x: swipeable.originalCenter.x + offsetIncrement, y: swipeable.view!.center.y)
                        swipeable.moveOriginalCenterRight(offsetIncrement: offsetIncrement)
                    }
                    
                    let snapBehav = UISnapBehavior(item: swipeable.view!, snapTo: snapTo)
                    snapBehav.damping = 0.4
                    animator.addBehavior(snapBehav)
                    
                    let resistance = UIDynamicItemBehavior(items: animator.items(in: swipeable.view!.frame))
                    resistance.allowsRotation = false
                    animator.addBehavior(resistance)
                } else {
                    if self.swipeDirection == .left {
                        swipeable.moveLeft(offsetIncrement: self.offsetIncrement)
                    } else if self.swipeDirection == .right {
                        swipeable.moveRight(offsetIncrement: self.offsetIncrement)
                    } else {
                        swipeable.moveToOriginalPosition()
                    }
                }
            }
            
            index += 1
        }
    }
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        if animating {
            if swipeDirection != .none {
                if swipeDirection == .left {
                    let elemRemove = swipeables.remove(at: 0)
                    if elemRemove.isPlaceholder {
                        let elemPop = stack.popLast()!
                        elemPop.moveLeft(offsetIncrement: offsetIncrement)
                        swipeables.append(elemPop)
                    } else {
                        stack.append(elemRemove)
                        swipeables.append(SwipeableElement())
                    }
                } else {
                    let elemRemove = swipeables.remove(at: 4)
                    if elemRemove.isPlaceholder {
                        let elemPop = stack.popLast()!
                        elemPop.moveRight(offsetIncrement: offsetIncrement)
                        swipeables.insert(elemPop, at: 0)
                    } else {
                        stack.append(elemRemove)
                        swipeables.insert(SwipeableElement(), at: 0)
                    }
                    
                    selected = swipeables[2]
                    selectedLeftNeighbour = swipeables[1]
                    selectedRightNeighbour = swipeables[3]
                }
            }
            
            animating = false
            
            print("dynamicAnimatorDidPause")
        } else {
            print("dynamicAnimatorDidPause - ignore")
        }
    }
}

