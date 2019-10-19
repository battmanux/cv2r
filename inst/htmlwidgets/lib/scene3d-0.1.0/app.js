
function init(data, el) {
  var camera, scene, renderer;
  var geometry, material, mesh;

	camera = new THREE.PerspectiveCamera( 70, el.offsetWidth / el.offsetHeight, 0.01, 10 );
	camera.position.z = 1;

	scene = new THREE.Scene();
  geometry = new THREE.BoxGeometry( 0.2, 0.2, 0.2 );
	
	//texture = (new THREE.TextureLoader()).load('data/textures/wire_sd.png');
  //material = new THREE.MeshBasicMaterial({map: texture});
  material = new THREE.MeshBasicMaterial( { color: 0xff0000, wireframe: false });
        
	mesh = new THREE.Mesh( geometry, material );
	scene.add( mesh );

	renderer = new THREE.WebGLRenderer( { antialias: true } );
	renderer.setSize( el.offsetWidth, el.offsetHeight );
	
	// controls
  controls = new THREE.OrbitControls( camera, renderer.domElement );
	
	//controls.addEventListener( 'change', render ); // call this only in static scenes (i.e., if there is no animation loop)
	
	//controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
	controls.dampingFactor = 0.25;
	controls.screenSpacePanning = false;
	controls.minDistance = 0.1;
	controls.maxDistance = 10;
	controls.maxPolarAngle = Math.PI / 2;

	el.appendChild( renderer.domElement );

  data.camera   = camera;
  data.scene    = scene;
  data.renderer = renderer;
  data.geometry = geometry;
  data.material = material;
  data.mesh     = mesh;
  data.controls = controls;
}

function linkToShiny() {
  Shiny.addCustomMessageHandler("tex", function(x) {
  
    mesh.material.map.image.src = x;
    mesh.material.map.needsUpdate = true;
    
  });
}


function animate(data) {

	requestAnimationFrame( function(x) { animate(data) } );
	
	data.controls.update();

	data.renderer.render( data.scene, data.camera );

}