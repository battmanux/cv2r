// !preview r2d3 data=list(list(id=0, scale = 1, data="iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAIAAABLixI0AAABRElEQVQ4EZ3BsY0UQQAAwW5jLEgKjwwgREQA+MQE3uivgbmf055+Vwiq5FqAcmBxTS4EKG+VnJMLKRcszsiZAOVKyQk5k/JQQoByV3JCzqQ8lBCg3JWckDMBymalPJSckAspm5WyWZyRCwEKWCwpYHFBjkLk4Gby6ief3vMF5FX8IZs8hMizjFcpvxUgoAEFyCKbybMIudPYSo2tZJG7EHmW8SrlodTYChCQxWSLEEJk6fMPv75jKUBIeSgBWUy2CDHZ+v7NDx/ZSki5K0BA7kLkQqZxoQAB2UwuZBoXShZ5CJE3MhaNNwqQRZ6ZHGQcaByUHMg2xmB5eXm53W6cGWNwMOccYwBzTkCWMQb/bs45xgDmnIAsYwxgzjnG4G/Uim3OySLLGIP/NedkkW2MwbNK5aBSWdQKmHOyyBtjDGDOyT/6BXOOqBqFSOIvAAAAAElFTkSuQmCC", type="data:image/png;base64"))
//

var l = data.length;

svg.selectAll('image')
  .data(data, function(d) {return d.id}).enter().append('image')
  .attr("xlink:href",  function(d) { return "data:image/"+d.type+";base64,"+d.data } )
  .attr("x", function(d, i) { return i * width / l  } )
  .attr("y", function(d, i) { return 0  } )
  .attr("width", function(d, i) { return  d.scale * width / l  } )
  .attr("height", function(d, i) { return d.scale * height / 1 });


svg.selectAll('image')
  .data(data, function(d) {return d.id}).exit().remove();
