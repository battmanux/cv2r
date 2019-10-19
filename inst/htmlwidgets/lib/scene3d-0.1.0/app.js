
function init(data, el) {
  var camera, scene, renderer;
  var geometry, material, mesh, light;

	camera = new THREE.PerspectiveCamera( 70, el.offsetWidth / el.offsetHeight, 0.01, 10 );
	camera.position.z = 1;

	scene = new THREE.Scene();
  //geometry = new THREE.BoxGeometry( 0.2, 0.2, 0.2 );
	
	//texture = (new THREE.TextureLoader()).load('data/textures/wire_sd.png');
  //material = new THREE.MeshBasicMaterial({map: texture});
  material = new THREE.MeshBasicMaterial( { color: 0xff0000, wireframe: false });
        
	///mesh = new THREE.Mesh( geometry, material );
	//scene.add( mesh );

    light = new THREE.HemisphereLight( 0xffffff, 0x444444 );
				light.position.set( 0, 200, 0 );
				scene.add( light );

	renderer = new THREE.WebGLRenderer( { antialias: true } );
	renderer.setSize( el.offsetWidth, el.offsetHeight );
	
	// controls
  controls = new THREE.OrbitControls( camera, renderer.domElement );
	
	//controls.addEventListener( 'change', render ); // call this only in static scenes (i.e., if there is no animation loop)
	
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
  data.geometry = geometry;
  data.material = material;
  data.mesh     = mesh;
  data.controls = controls;
  data.light    = light;
  data.gltfloader = new THREE.GLTFLoader();
}

function linkToShiny() {
  Shiny.addCustomMessageHandler("tex", function(x) {
  
    mesh.material.map.image.src = x;
    mesh.material.map.needsUpdate = true;
    
  });
}

function addGround(data) {
	// ground
	var mesh2 = new THREE.Mesh( new THREE.PlaneBufferGeometry( 100, 100 ),
				new THREE.MeshPhongMaterial( { color: 0x444444, depthWrite: false } ) );
	mesh2.rotation.x = - Math.PI / 2;
	mesh2.receiveShadow = true;
	scene.add( mesh2 );

	var grid = new THREE.GridHelper( 1000, 10, 0x000000, 0x000000 );
	grid.material.opacity = 0.2;
	grid.material.transparent = true;
	scene.add( grid );
    
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