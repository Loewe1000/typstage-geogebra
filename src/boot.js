
(function(){
var api=null,base=null,live=false,q=[],busy=false,pending=null,running={};
function tween(w){
 var from0=w.from==null?api.getValue(w.name):w.from,dur=w.duration||600,t0=null;
 if(running[w.name])cancelAnimationFrame(running[w.name]);
 if(w.from!=null)api.setValue(w.name,w.from);
 function frame(now){
  if(t0===null)t0=now;
  var p=dur>0?Math.min(1,(now-t0)/dur):1;
  var e=w.easing==="linear"?p:(p<0.5?2*p*p:1-Math.pow(-2*p+2,2)/2);
  api.setValue(w.name,from0+(w.to-from0)*e);
  if(p<1)running[w.name]=requestAnimationFrame(frame);else delete running[w.name];
 }
 running[w.name]=requestAnimationFrame(frame);
}
function stopTweens(){for(var n in running)cancelAnimationFrame(running[n]);running={};}
function apply(j,sofort){
 var bad=[];
 if(j.set)for(var k in j.set)api.setValue(k,j.set[k]);
 if(j.cmd)for(var i=0;i<j.cmd.length;i++){if(api.evalCommand(j.cmd[i])===false)bad.push(j.cmd[i]);}
 if(j.view){var v=j.view;
  if(v.coords)api.setCoordSystem(v.coords[0],v.coords[1],v.coords[2],v.coords[3]);
  if(v.grid!=null)api.setGridVisible(v.grid);
  if(v.axes)api.setAxesVisible(v.axes[0],v.axes[1]);}
 if(j.vis)for(var i=0;i<j.vis.objects.length;i++)api.setVisible(j.vis.objects[i],j.vis.on);
 if(j.style){var t=j.style,i,o;
  for(i=0;i<t.objects.length;i++){o=t.objects[i];
   if(t.color)api.setColor(o,t.color[0],t.color[1],t.color[2]);
   if(t.thickness!=null)api.setLineThickness(o,t.thickness);
   if(t.lineStyle!=null)api.setLineStyle(o,t.lineStyle);
   if(t.filling!=null)api.setFilling(o,t.filling);
   if(t.pointSize!=null)api.setPointSize(o,t.pointSize);
   if(t.trace!=null)api.setTrace(o,t.trace);
   if(t.label!=null)api.setLabelVisible(o,t.label);
   if(t.labelMode!=null)api.setLabelStyle(o,t.labelMode);
   if(t.fixed!=null)api.setFixed(o,t.fixed,true);
   if(t.caption!=null)api.setCaption(o,t.caption);
   if(t.layer!=null)api.setLayer(o,t.layer);
   if(t.coords)api.setCoords(o,t.coords[0],t.coords[1]);}}
 if(j.anim){var a=j.anim,i;
  for(i=0;i<a.objects.length;i++){
   if(a.speed!=null)api.setAnimationSpeed(a.objects[i],a.speed);
   api.setAnimating(a.objects[i],a.playing!==false);}
  for(i=0;i<(a.trace||[]).length;i++)api.setTrace(a.trace[i],true);
  if(a.playing===false)api.stopAnimation();else api.startAnimation();}
 if(j.tween){if(sofort)api.setValue(j.tween.name,j.tween.to);else tween(j.tween);}
 if(bad.length)try{parent.postMessage({typstage:1,failed:bad,who:__ID__},"*");}catch(e){}
}
function play(jobs,sofort){for(var i=0;i<(jobs||[]).length;i++)apply(jobs[i],sofort);}
// ── Mirroring, the second route from the speaker view ─────────────────────
//
// In pointer mode the speaker operates the applet in front of them, not the
// one across the room. What comes of it is reported here and put into the
// other copy. Only what a hand touched: an animation running on both sides
// anyway would otherwise send sixty values a second for nothing.
var beruehrt=0,los=0,takt=0,offen={};
function melde(s){try{parent.postMessage({typstage:1,spiegel:__ID__,stand:s},"*");}catch(e){}}
function typVon(n){try{return api.getObjectType(n);}catch(e){return "";}}
// A point travels as two numbers, a slider as one. Everything else takes the
// long way round through its XML, which is correct for any object and too
// expensive to use for the two cases above.
function standVon(n){
 var t=typVon(n);
 try{
  if(t==="point"||t==="vector")
   return {n:n,t:"p",x:api.getXcoord(n),y:api.getYcoord(n),z:api.getZcoord(n)};
  if(t==="numeric"||t==="angle")return {n:n,t:"v",v:api.getValue(n)};
  return {n:n,t:"x",x:api.getXML(n)};
 }catch(e){return null;}
}
// One report per object and frame. A drag fires the listener at the rate of
// the screen, and every value but the last is stale before it arrives.
// Only what a hand can move. `registerUpdateListener` fires for every object
// that recomputed, so dragging one point on a half circle reported the point,
// both segments and the angle, four states for one movement. The three
// dependent ones are not merely redundant, since the other side works them
// out from the point by itself: their XML redefines them over there, and that
// wipes the trace the dragged point had just left behind.
function sammle(n){
 if(!beruehrt)return;
 try{if(api.isMoveable&&!api.isMoveable(n))return;}catch(e){}
 offen[n]=1;
 if(takt)return;
 takt=requestAnimationFrame(function(){
  takt=0;var o=offen;offen={};
  for(var n in o){var s=standVon(n);if(s)melde(s);}
 });
}
// Something was created, deleted or renamed. That cannot be described per
// object, so the whole construction goes across.
function sammleAlles(){
 if(!beruehrt)return;
 try{melde({t:"all",x:api.getXML()});}catch(e){}
}
function spiegelAn(s){
 try{
  // Two arguments for a point in the plane, three only where there really is
  // a third.
  if(s.t==="p"){if(s.z)api.setCoords(s.n,s.x,s.y,s.z);else api.setCoords(s.n,s.x,s.y);}
  else if(s.t==="v")api.setValue(s.n,s.v);
  else if(s.t==="x")api.evalXML(s.x);
  else if(s.t==="all")api.setXML(s.x);
  else if(s.t==="view")api.setCoordSystem(s.a,s.b,s.c,s.d);
 }catch(e){}
}
// The window in which a change counts as made by hand. `pointerup` alone is
// too early: GeoGebra settles a dragged object one turn later, and that last
// value is the one that matters.
function beruehrung(){
 addEventListener("pointerdown",function(){beruehrt=1;if(los){clearTimeout(los);los=0;}},true);
 addEventListener("pointerup",function(){
  if(los)clearTimeout(los);
  los=setTimeout(function(){beruehrt=0;los=0;},400);
 },true);
 addEventListener("pointercancel",function(){beruehrt=0;},true);
}

function run(m){
 if(!m||m.typstage!==1)return;
 if(m.spiegel&&m.stand){if(live)spiegelAn(m.stand);return;}
 if(!live){q=[m];return;}
 if(busy){pending=m;return;}
 if(m.stop){stopTweens();try{api.stopAnimation();}catch(e){}return;}
 if(m.reset&&base!=null){
  busy=true;stopTweens();
  try{api.setRepaintingActive(false);}catch(e){}
  api.setBase64(base,function(){
   try{api.setRepaintingActive(false);}catch(e){}
   // The base carries the size it was taken at. If it brought a different
   // one back, the next `passe` has to see that, so the memory is cleared.
   breit=0;hoch=0;passe();
   play(m.jobs,true);
   try{api.setRepaintingActive(true);}catch(e){}
   busy=false;var n=pending;pending=null;if(n)run(n);});
  return;}
 play(m.jobs,false);
}
addEventListener("message",function(e){run(e.data);});

// ── The applet's size ─────────────────────────────────────────────────────
//
// The frame is spanned in points of the slide and then zoomed onto the
// stage, so the inner viewport is the box's size in the slide's own units:
// the same number in the talk and in the speaker view, whatever size the two
// windows have. That is the only figure that is right here. A number written
// in at compile time cannot be, because `width: 100%` is only settled once
// the slide has been laid out, and the applet then drew a third the width of
// the box it sat in.
var breit=0,hoch=0;
function passe(){
 if(!api)return;
 var w=Math.round(innerWidth),h=Math.round(innerHeight);
 if(w<40||h<40||(w===breit&&h===hoch))return;
 breit=w;hoch=h;
 // `setSize` is the documented way; older applets only know the two
 // single setters.
 try{if(api.setSize)api.setSize(w,h);else{api.setWidth(w);api.setHeight(h);}}catch(e){}
 try{api.recalculateEnvironments();}catch(e){}
}
// The applet starts before its frame has a size — when it grows it has to
// take the new one, otherwise it stays small inside a large area.
addEventListener("resize",passe);
var p=__PARAMS__;
p.appletOnLoad=function(a){
 api=a;
 __BOOTVIEW__
 // Before the base is taken, so a reset restores the applet at the size it
 // actually has on the slide.
 passe();
 beruehrung();
 try{
  a.registerUpdateListener(sammle);
  a.registerAddListener(sammleAlles);
  a.registerRemoveListener(sammleAlles);
  a.registerRenameListener(sammleAlles);
  a.registerClearListener(sammleAlles);
  // Panning and zooming change no object and would otherwise not travel,
  // although it is the most visible thing a hand does here.
  a.registerClientListener(function(ev){
   var t=ev&&(ev.type||ev[0]);
   if(t!=="viewChanged2D"||!beruehrt)return;
   melde({t:"view",a:ev.xZero,b:ev.yZero,c:ev.xscale,d:ev.yscale});
  });
 }catch(e){}
 a.getBase64(function(b){
  base=b;live=true;
  var r=q;q=[];for(var i=0;i<r.length;i++)run(r[i]);
  // `spiegel` is the announcement that this document can be operated
  // locally and reports the result. Without it the runtime keeps the
  // pointer away from the frame in the speaker view and takes the other
  // route, which is right for a document that cannot do this.
  try{parent.postMessage({typstage:1,ready:__ID__,spiegel:1},"*");}catch(e){}});
};
__CODEBASE__
new GGBApplet(p,true).inject("ts-ggb");
})();
