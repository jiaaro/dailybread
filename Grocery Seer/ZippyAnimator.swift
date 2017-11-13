//
//  ZippyModalSegue.swift
//  Daily Bread
//
//  Created by James Robert on 2/27/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//

import Foundation


class ZippyModalTransitioningDelegate : NSObject, UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(
        presented: UIViewController,
        presentingController presenting: UIViewController,
        sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return ZippyModalSlideOverAnimator()
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = ZippyModalSlideOverAnimator()
        animator.reverse = true
        return animator
//        return nil
    }
}


class ZippyModalSlideOverAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    var reverse = false
    let view_spacing: CGFloat = 10
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container_view = transitionContext.containerView
        let dst = transitionContext.viewController(forKey: .to)!
        let src = transitionContext.viewController(forKey: .from)!
        
        container_view.addSubview(src.view)
        container_view.addSubview(dst.view)
        
        let duration = self.transitionDuration(using: transitionContext)
        let distance = src.view.frame.height
        
        let src_start = CGAffineTransform(translationX: 0, y: 0)
        var dst_start = CGAffineTransform(translationX: 0, y: 0)
        var src_end = CGAffineTransform(translationX: 0, y: 0)
        let dst_end = CGAffineTransform(translationX: 0, y: 0)
        
        if !self.reverse {
            dst_start = CGAffineTransform(translationX: 0, y: distance)
        }
        else {
            src_end = CGAffineTransform(translationX: 0, y: distance)
            container_view.sendSubview(toBack: dst.view)
        }
        
        src.view.transform = src_start
        dst.view.transform = dst_start
        
        UIView.animate(withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: .curveEaseInOut,
            animations: {
                src.view.transform = src_end
                dst.view.transform = dst_end
            },
            completion: {
                (finished) in
                src.view.removeFromSuperview()
                dst.view.transform = .identity
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                
                if self.reverse {
                    // hack to fix a weird bug. see http://stackoverflow.com/a/24589312/2908
                    UIApplication.shared.keyWindow!.addSubview(dst.view)
                }
                
        })
        
    }
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if !self.reverse {
            return 0.25
        }
        else {
            return 0.35
        }
    }
}

class ZippyModalSidewaysAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    var reverse = false
    let view_spacing: CGFloat = 10
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container_view = transitionContext.containerView
        let dst = transitionContext.viewController(forKey: .to)!
        let src = transitionContext.viewController(forKey: .from)!
        
        container_view.addSubview(dst.view)
        container_view.addSubview(src.view)
        
        let duration = self.transitionDuration(using: transitionContext)
        let distance = src.view.frame.width + view_spacing
        
        let src_start = CGAffineTransform(translationX: 0, y: 0)
        var dst_start = CGAffineTransform(translationX: 0, y: 0)
        var src_end = CGAffineTransform(translationX: 0, y: 0)
        let dst_end = CGAffineTransform(translationX: 0, y: 0)
        
        if !self.reverse {
            src_end = CGAffineTransform(translationX: -distance, y: 0)
            dst_start = CGAffineTransform(translationX: distance, y: 0)
        }
        else {
            src_end = CGAffineTransform(translationX: distance, y: 0)
            dst_start = CGAffineTransform(translationX: -distance, y: 0)
            
        }

            
        src.view.transform = src_start
        dst.view.transform = dst_start

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: .curveEaseOut,
            animations: {
                src.view.transform = src_end
                dst.view.transform = dst_end
            },
            completion: {
                (finished) in
                src.view.removeFromSuperview()
                dst.view.transform = .identity
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                
                if self.reverse {
                    // hack to fix a weird bug. see http://stackoverflow.com/a/24589312/2908
                    UIApplication.shared.keyWindow!.addSubview(dst.view)
                }

        })
        
    }
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
}







//class ZippyModalSegue : UIStoryboardSegue {
//
//    override func perform() {
//        let src = self.sourceViewController as UIViewController
//        let dst = self.destinationViewController as UIViewController
//
//        let transition = CATransition()
//        transition.duration = 0.25
//        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
//
//        transition.type = kCATransitionMoveIn
//        transition.subtype = kCATransitionFromTop
//
//        src.view.window?.layer.addAnimation(transition, forKey: kCATransition)
//        src.presentViewController(dst, animated: false, completion: nil)
//    }
//}


//class ZippyModalSegue : UIStoryboardSegue {
//
//    override func perform() {
//        let window = UIApplication.sharedApplication().keyWindow!
//        let src = self.sourceViewController as UIViewController
//        let dst = self.destinationViewController as UIViewController
//
//        src.presentViewController(dst, animated: false) {
//            window.insertSubview(src.view, aboveSubview: dst.view)
//            window.sendSubviewToBack(src.view)
//            dst.view.transform = CGAffineTransformMakeTranslation(0.0, src.view.frame.height)
//
//            UIView.animateWithDuration(2.0,
//                delay: 0,
//                options: UIViewAnimationOptions.CurveEaseOut,
//                animations: {
//                    dst.view.transform = CGAffineTransformMakeTranslation(0, 0)
//                },
//                completion: {
//                    (finished) in
//                    src.view.removeFromSuperview()
//            })
//        }
//    }
//}
//
//extension ZippyModalSegue : UIViewControllerTransitioningDelegate {
//    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController!, sourceViewController source: UIViewController) -> UIPresentationController? {
//        let presentationController = ZippyPresentationController(presentedViewController: presented, presentingViewController: source)
//        return presentationController;
//    }
//}
//
//class ZippyPresentationController : UIPresentationController {
//    override func presentationTransitionWillBegin() {
//        // code
//    }
//}
