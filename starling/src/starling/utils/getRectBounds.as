package starling.utils {
    import flash.geom.Rectangle;
    import flash.geom.Point;
    import flash.geom.Matrix;
    import starling.utils.getPointsBounds;
    public function getRectBounds(rect:Rectangle,matrix:Matrix,resultRect:Rectangle=null):Rectangle {
        if(resultRect==null) resultRect=new Rectangle();
        var points:Vector.<Point>=getRectPoints(rect,matrix);
        getPointsBounds(points,resultRect);
        return resultRect;
    }
}
