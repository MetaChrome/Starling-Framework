// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.errors.AbstractClassError;
    import starling.events.Event;
    import starling.utils.transformCoords;
	import starling.core.Starling;
	import starling.textures.RenderTexture;
	import starling.display.Image;
	import starling.utils.getSmallestRect;
    import starling.utils.getRectBounds;
    import starling.core.QuadBatch;
    
    /**
     *  A DisplayObjectContainer represents a collection of display objects.
     *  It is the base class of all display objects that act as a container for other objects. By 
     *  maintaining an ordered list of children, it defines the back-to-front positioning of the 
     *  children within the display tree.
     *  
     *  <p>A container does not a have size in itself. The width and height properties represent the 
     *  extents of its children. Changing those properties will scale all children accordingly.</p>
     *  
     *  <p>As this is an abstract class, you can't instantiate it directly, but have to 
     *  use a subclass instead. The most lightweight container class is "Sprite".</p>
     *  
     *  <strong>Adding and removing children</strong>
     *  
     *  <p>The class defines methods that allow you to add or remove children. When you add a child, 
     *  it will be added at the frontmost position, possibly occluding a child that was added 
     *  before. You can access the children via an index. The first child will have index 0, the 
     *  second child index 1, etc.</p> 
     *  
     *  Adding and removing objects from a container triggers non-bubbling events.
     *  
     *  <ul>
     *   <li><code>Event.ADDED</code>: the object was added to a parent.</li>
     *   <li><code>Event.ADDED_TO_STAGE</code>: the object was added to a parent that is 
     *       connected to the stage, thus becoming visible now.</li>
     *   <li><code>Event.REMOVED</code>: the object was removed from a parent.</li>
     *   <li><code>Event.REMOVED_FROM_STAGE</code>: the object was removed from a parent that 
     *       is connected to the stage, thus becoming invisible now.</li>
     *  </ul>
     *  
     *  Especially the <code>ADDED_TO_STAGE</code> event is very helpful, as it allows you to 
     *  automatically execute some logic (e.g. start an animation) when an object is rendered the 
     *  first time.
     *  
     *  @see Sprite
     *  @see DisplayObject
     */
    public class DisplayObjectContainer extends DisplayObject
    {
        // members
        
        private var mChildren:Vector.<DisplayObject>;
        private var mFlattenedContents:Vector.<QuadBatch>;
        
        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperPoint:Point = new Point();
        private static var sHelperRect:Rectangle=new Rectangle();
        // construction
        
        /** @private */
        public function DisplayObjectContainer()
        {
            if (getQualifiedClassName(this) == "starling.display::DisplayObjectContainer")
                throw new AbstractClassError();
            
            mChildren = new <DisplayObject>[];
        }
        
        /** Disposes the resources of all children. */
        public override function dispose():void
        {
            unflatten();
            var numChildren:int = mChildren.length;
            
            for (var i:int=0; i<numChildren; ++i)
                mChildren[i].dispose();
                
            super.dispose();
        }
        
        // child management
        
        /** Adds a child to the container. It will be at the frontmost position. */
        public function addChild(child:DisplayObject):void
        {
            addChildAt(child, numChildren);
        }
        
        /** Adds a child to the container at a certain index. */
        public function addChildAt(child:DisplayObject, index:int):void
        {
            if (index >= 0 && index <= numChildren)
            {
                child.removeFromParent();
                mChildren.splice(index, 0, child);
                child.setParent(this);                
                child.dispatchEvent(new Event(Event.ADDED, true));
                if (stage) child.dispatchEventOnChildren(new Event(Event.ADDED_TO_STAGE));
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
        
        /** Removes a child from the container. If the object is not a child, nothing happens. 
         *  If requested, the child will be disposed right away. */
        public function removeChild(child:DisplayObject, dispose:Boolean=false):void
        {
            var childIndex:int = getChildIndex(child);
            if (childIndex != -1) removeChildAt(childIndex, dispose);
        }
        
        /** Removes a child at a certain index. Children above the child will move down. If
         *  requested, the child will be disposed right away. */
        public function removeChildAt(index:int, dispose:Boolean=false):void
        {
            if (index >= 0 && index < numChildren)
            {
                var child:DisplayObject = mChildren[index];
                child.dispatchEvent(new Event(Event.REMOVED, true));
                if (stage) child.dispatchEventOnChildren(new Event(Event.REMOVED_FROM_STAGE));
                child.setParent(null);
                mChildren.splice(index, 1);
                if (dispose) child.dispose();
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
        
        /** Removes a range of children from the container (endIndex included). 
         *  If no arguments are given, all children will be removed. */
        public function removeChildren(beginIndex:int=0, endIndex:int=-1, dispose:Boolean=false):void
        {
            if (endIndex < 0 || endIndex >= numChildren) 
                endIndex = numChildren - 1;
            
            for (var i:int=beginIndex; i<=endIndex; ++i)
                removeChildAt(beginIndex, dispose);
        }
        
        /** Returns a child object at a certain index. */
        public function getChildAt(index:int):DisplayObject
        {
            if (index >= 0 && index < numChildren)
                return mChildren[index];
            else
                throw new RangeError("Invalid child index");
        }
        
        /** Returns a child object with a certain name (non-recursively). */
        public function getChildByName(name:String):DisplayObject
        {
            var numChildren:int = mChildren.length;
            for (var i:int=0; i<numChildren; ++i)
                if (mChildren[i].name == name) return mChildren[i];

            return null;
        }
        
        /** Returns the index of a child within the container, or "-1" if it is not found. */
        public function getChildIndex(child:DisplayObject):int
        {
            return mChildren.indexOf(child);
        }
        
        /** Moves a child to a certain index. Children at and after the replaced position move up.*/
        public function setChildIndex(child:DisplayObject, index:int):void
        {
            var oldIndex:int = getChildIndex(child);
            if (oldIndex == -1) throw new ArgumentError("Not a child of this container");
            mChildren.splice(oldIndex, 1);
            mChildren.splice(index, 0, child);
        }
        
        /** Swaps the indexes of two children. */
        public function swapChildren(child1:DisplayObject, child2:DisplayObject):void
        {
            var index1:int = getChildIndex(child1);
            var index2:int = getChildIndex(child2);
            if (index1 == -1 || index2 == -1) throw new ArgumentError("Not a child of this container");
            swapChildrenAt(index1, index2);
        }
        
        /** Swaps the indexes of two children. */
        public function swapChildrenAt(index1:int, index2:int):void
        {
            var child1:DisplayObject = getChildAt(index1);
            var child2:DisplayObject = getChildAt(index2);
            mChildren[index1] = child2;
            mChildren[index2] = child1;
        }
        
        /** Sorts the children according to a given function (that works just like the sort function
         *  of the Vector class). */
        public function sortChildren(compareFunction:Function):void
        {
            mChildren = mChildren.sort(compareFunction);
        }
        
        /** Determines if a certain object is a child of the container (recursively). */
        public function contains(child:DisplayObject):Boolean
        {
            if (child == this) return true;
            
            var numChildren:int = mChildren.length;
            for (var i:int=0; i<numChildren; ++i)
            {
                var currentChild:DisplayObject = mChildren[i];
                var currentChildContainer:DisplayObjectContainer = currentChild as DisplayObjectContainer;
                
                if (currentChildContainer && currentChildContainer.contains(child)) return true;
                else if (currentChild == child) return true;
            }
            
            return false;
        }
        
        /** @inheritDoc */ 
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var numChildren:int = mChildren.length;
            
            if (numChildren == 0)
            {
                getTransformationMatrix(targetSpace, sHelperMatrix);
                transformCoords(sHelperMatrix, 0.0, 0.0, sHelperPoint);
                
                resultRect.x = sHelperPoint.x;
                resultRect.y = sHelperPoint.y;
                resultRect.width = resultRect.height = 0;
                
                return resultRect;
            }
            else {
				if (numChildren == 1)
	            {
	                mChildren[0].getBounds(targetSpace, resultRect);
	            }
	            else
	            {
	                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
	                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
	                for (var i:int=0; i<numChildren; ++i)
	                {
	                    mChildren[i].getBounds(targetSpace, resultRect);
	                    minX = minX < resultRect.x ? minX : resultRect.x;
	                    maxX = maxX > resultRect.right ? maxX : resultRect.right;
	                    minY = minY < resultRect.y ? minY : resultRect.y;
	                    maxY = maxY > resultRect.bottom ? maxY : resultRect.bottom;
	                }
	                resultRect.x = minX;
	                resultRect.y = minY;
	                resultRect.width  = maxX - minX;
	                resultRect.height = maxY - minY;
	            }    
				if(mScrollRect!=null)
				{
                    var scrollRectBounds:Rectangle;
                    if(targetSpace==this) {
                        scrollRectBounds=scrollRect.clone();
                        scrollRectBounds.x=0;
                        scrollRectBounds.y=0;
                    } else {
                        getTransformationMatrix(targetSpace, sHelperMatrix);
                        scrollRectBounds=getRectBounds(scrollRect,sHelperMatrix);
                    }
					getSmallestRect(resultRect,scrollRectBounds,resultRect);
				}
                return resultRect;
			}
        }
        
        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            if(mScrollRect) {
				if(!mScrollRect.containsPoint(localPoint)) return null;
			}
            var localX:Number = localPoint.x;
            var localY:Number = localPoint.y;
            
            var numChildren:int = mChildren.length;
            for (var i:int=numChildren-1; i>=0; --i) // front to back!
            {
                var child:DisplayObject = mChildren[i];
                getTransformationMatrix(child, sHelperMatrix);
                
                transformCoords(sHelperMatrix, localX, localY, sHelperPoint);
                var target:DisplayObject = child.hitTest(sHelperPoint, forTouch);
                
                if (target) return target;
            }
            
            return null;
        }
        
        /** Indicates if the sprite was flattened. */
        public function get isFlattened():Boolean { return mFlattenedContents != null; }
        
        /** Optimizes the sprite for optimal rendering performance. Changes in the
         *  children of a flattened sprite will not be displayed any longer. For this to happen,
         *  either call <code>flatten</code> again, or <code>unflatten</code> the sprite. */
        public function flatten():void
        {
            dispatchEventOnChildren(new Event(Event.FLATTEN));
            
            if (mFlattenedContents == null)
            {
                mFlattenedContents = new <QuadBatch>[];
                Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            }
            
            QuadBatch.compile(this, mFlattenedContents);
        }
        
        /** Removes the rendering optimizations that were created when flattening the sprite.
         *  Changes to the sprite's children will become immediately visible again. */ 
        public function unflatten():void
        {
            if (mFlattenedContents)
            {
                Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
                var numBatches:int = mFlattenedContents.length;
                
                for (var i:int=0; i<numBatches; ++i)
                    mFlattenedContents[i].dispose();
                
                mFlattenedContents = null;
            }
        }
        
        private function onContextCreated(event:Event):void
        {
            if (mFlattenedContents)
            {
                mFlattenedContents = new <QuadBatch>[];
                flatten();
            }
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, alpha:Number):void
        {
			if(mScrollRect && !mRenderingScrollRectTexture)
			{
				getTransformationMatrix(support.rootDisplayObject,sHelperMatrix);
				var yTransform:Point=sHelperMatrix.deltaTransformPoint(new Point(1,0));
				//var rotation:Number=Math.atan2(yTransform.y,yTransform.x)-Math.PI/2;
				if(yTransform.y==0) {
					var bounds:Rectangle=getBounds(support.rootDisplayObject);
					if(support.previousScissorRect!=null) {
						var previousScissorRect:Rectangle=support.previousScissorRect;
						getSmallestRect(bounds,previousScissorRect,bounds);
					}
					support.previousScissorRect=bounds;
					support.finishQuadBatch();
					support.translateMatrix(-mScrollRect.x, -mScrollRect.y);
					Starling.context.setScissorRectangle(bounds);
				} else {
					mRenderingScrollRectTexture=true;
					var xTransform:Point=sHelperMatrix.deltaTransformPoint(new Point(0,1));
					var stageScaleX:Number=xTransform.length;
					var stageScaleY:Number=yTransform.length;
					var renderTexture:RenderTexture=new RenderTexture(mScrollRect.width*stageScaleX,mScrollRect.height*stageScaleY);
                    renderTexture.support.rootDisplayObject=this;
					function drawingBlock():void {
						this.support.scaleMatrix(stageScaleX,stageScaleY);
						this.support.translateMatrix(-mScrollRect.x,-mScrollRect.y);
						render(this.support,1.0);
					}
					renderTexture.drawBundled(drawingBlock);
					var image:Image=new Image(renderTexture);
					support.pushMatrix();
					support.scaleMatrix(1/stageScaleX,1/stageScaleY);
					image.render(support,alpha);
					support.popMatrix();
                    mRenderingScrollRectTexture=false;
					return;
				}
			}
            var i:int;
            if (mFlattenedContents)
            {
                if(mScrollRect==null) {
                	support.finishQuadBatch();
                }
                
                alpha *= this.alpha;
                var numBatches:int = mFlattenedContents.length;
                
                for (i=0; i<numBatches; ++i)
                    mFlattenedContents[i].render(support.mvpMatrix, alpha);
            } else {
	            alpha *= this.alpha;
	            var numChildren:int = mChildren.length;
	            
	            for (i=0; i<numChildren; ++i)
	            {
	                var child:DisplayObject = mChildren[i];
	                if (child.alpha != 0.0 && child.visible && child.scaleX != 0.0 && child.scaleY != 0.0)
	                {
	                    support.pushMatrix();
	                    support.transformMatrix(child);
	                    child.render(support, alpha);
	                    support.popMatrix();
	                }
	            }
            }
			if(mScrollRect && !mRenderingScrollRectTexture) {
				support.finishQuadBatch();
				support.translateMatrix(mScrollRect.x, mScrollRect.y);
				if(previousScissorRect!=null) {
					support.previousScissorRect=previousScissorRect;
					Starling.context.setScissorRectangle(previousScissorRect);
				} else {
					support.previousScissorRect=null;
					Starling.context.setScissorRectangle(null);
				}
			}
        }
        
        /** Dispatches an event on all children (recursively). The event must not bubble. */
        public function broadcastEvent(event:Event):void
        {
            if (event.bubbles) 
                throw new ArgumentError("Broadcast of bubbling events is prohibited");
            
            dispatchEventOnChildren(event);
        }
        
        /** @private */
        internal override function dispatchEventOnChildren(event:Event):void 
        { 
            // the event listeners might modify the display tree, which could make the loop crash. 
            // thus, we collect them in a list and iterate over that list instead.
            
            var listeners:Vector.<DisplayObject> = new <DisplayObject>[];
            getChildEventListeners(this, event.type, listeners);
            var numListeners:int = listeners.length;
            
            for (var i:int=0; i<numListeners; ++i)
                listeners[i].dispatchEvent(event);
        }
        
        private function getChildEventListeners(object:DisplayObject, eventType:String, 
                                                listeners:Vector.<DisplayObject>):void
        {
            var container:DisplayObjectContainer = object as DisplayObjectContainer;
            
            if (object.hasEventListener(eventType))
                listeners.push(object);
            
            if (container)
            {
                var children:Vector.<DisplayObject> = container.mChildren;
                var numChildren:int = children.length;
                
                for (var i:int=0; i<numChildren; ++i)
                    getChildEventListeners(children[i], eventType, listeners);
            }
        }
        
        /** The number of children of this container. */
        public function get numChildren():int { return mChildren.length; }        
    }
}
