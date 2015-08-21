function render() {
  var c = document.getElementById("myCanvas");
  var ctx = c.getContext("2d");
  ctx.beginPath();
  ctx.moveTo(250, 250);
  ctx.lineTo(350, 250);
  ctx.moveTo(350, 250);
  ctx.lineTo(341, 255);
  ctx.moveTo(341, 255);
  ctx.lineTo(338, 246);
  ctx.stroke();
}