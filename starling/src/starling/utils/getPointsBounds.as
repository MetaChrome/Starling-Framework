package starling.utils {
    import flash.geom.Rectangle;
    public function getPointsBounds(points:*,resultRect:Rectangle):Rectangle {
	    if(resultRect==null) resultRect=new Rectangle();
	    var minX:Number=Number.MAX_VALUE,maxX:Number=Number.MIN_VALUE,
	    	minY:Number=Number.MAX_VALUE,maxY:Number=Number.MIN_VALUE;
        points=(points as Vector.<*>);
	    for(var pointsc:int=0;pointsc<points.length;++pointsc) {
	        var point:Object=points[pointsc];
	        minX=point.x<minX?point.x:minX;
	        maxX=point.x>maxX?point.x:maxX;
	        minY=point.y<minY?point.y:minY;
	        maxY=point.y>maxY?point.y:maxY;
	    }
	    resultRect.x=minX;
	    resultRect.right=maxX;
	    resultRect.y=minY;
	    resultRect.bottom=maxY;
	    return resultRect;
    }
}
