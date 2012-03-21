package starling.utils {
    import flash.geom.Point;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import starling.utils.transformCoords;
	public function getRectPoints(rect:Rectangle,matrix:Matrix=null):Vector.<Point> {
        var point1:Point,point2:Point,point3:Point,point4:Point;
        if(matrix!=null) {
	        point1=transformCoords(matrix,rect.x,rect.y);
	        point2=transformCoords(matrix,rect.right,rect.y);
	        point3=transformCoords(matrix,rect.right,rect.bottom);
	        point4=transformCoords(matrix,rect.x,rect.bottom);
        } else {
            point1=new Point(rect.x,rect.y);
            point2=new Point(rect.right,rect.y);
            point3=new Point(rect.right,rect.bottom);
            point4=new Point(rect.x,rect.bottom);
        }
        var points:Vector.<Point>=new <Point>[point1,point2,point3,point4];
        return points;
	}
}
