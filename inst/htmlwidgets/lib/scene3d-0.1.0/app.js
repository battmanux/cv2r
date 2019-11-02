
function init(data, el) {
  var camera, scene, renderer;
  var light;

	camera = new THREE.PerspectiveCamera( 70, el.offsetWidth / el.offsetHeight, 0.01, 10 );
	camera.position.z = 1;

	scene = new THREE.Scene();
    
    light = new THREE.HemisphereLight( 0xffffff, 0x444444 );
				light.position.set( 0, 200, 0 );
				scene.add( light );

	renderer = new THREE.WebGLRenderer( { antialias: true } );
	renderer.setSize( el.offsetWidth, el.offsetHeight );
	
	// controls
    controls = new THREE.OrbitControls( camera, renderer.domElement );
	
	controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
	controls.dampingFactor = 0.25;
	controls.screenSpacePanning = false;
	controls.minDistance = 0.1;
	controls.maxDistance = 10;
	controls.maxPolarAngle = Math.PI / 2;

	el.appendChild( renderer.domElement );

  data.camera   = camera;
  data.scene    = scene;
  data.renderer = renderer;
  data.controls = controls;
  data.light    = light;
  data.gltfloader = new THREE.GLTFLoader();
  data.objloader = new THREE.OBJLoader();
  
  if (HTMLWidgets.shinyMode) {
   linkToShiny(data);
  }
  
}

function linkToShiny(wg_data) {
  Shiny.addCustomMessageHandler(wg_data.id+"_execute", function(call) {
    var scene = wg_data.scene;
    var data = call.data;
    eval(call.code);
  });
}

function addGround(data) {
	// ground
	var mesh2 = new THREE.Mesh( new THREE.PlaneBufferGeometry( 100, 100 ),
				new THREE.MeshPhongMaterial( { color: 0x444444, depthWrite: false } ) );
	mesh2.rotation.x = - Math.PI / 2;
	mesh2.receiveShadow = true;
	data.scene.add( mesh2 );

	var grid = new THREE.GridHelper( 1000, 10, 0x000000, 0x000000 );
	grid.material.opacity = 0.2;
	grid.material.transparent = true;
	data.scene.add( grid );
    
}


function loadObj(data, text) {
    data.scene.add(
        data.objloader.parse( text ) );
}

function loadGltf(data, json) {
    data.gltfloader.parse( json, ".", function ( gltf ) {
    		data.scene.add( gltf.scene );
    
    		gltf.animations; // Array<THREE.AnimationClip>
    		gltf.scene; // THREE.Scene
    		gltf.scenes; // Array<THREE.Scene>
    		gltf.cameras; // Array<THREE.Camera>
    		gltf.asset; // Object
    
	} );
}
	
function animate(data) {

	requestAnimationFrame( function(x) { animate(data) } );
	
	data.controls.update();

	data.renderer.render( data.scene, data.camera );

}