package starling.utils {
    import flash.geom.Rectangle;
    public function getSmallestRect(rect1:Rectangle,rect2:Rectangle,
		resultRect:Rectangle=null):Rectangle {
		if(resultRect==null) resultRect=new Rectangle();
		var minX:Number,maxX:Number,minY:Number,maxY:Number;
		minX = rect1.x < rect2.x ? rect2.x : rect1.x;
		minY = rect1.y < rect2.y ? rect2.y : rect1.y;
		maxX = rect1.right > rect2.right ? rect2.right : rect1.right;
		maxY = rect1.bottom > rect2.bottom ? rect2.bottom : rect1.bottom;
		resultRect.x=minX;
		resultRect.y=minY;
		resultRect.width=maxX - minX;
		resultRect.height=maxY - minY;
		return resultRect;
	}
}
