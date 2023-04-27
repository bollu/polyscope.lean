import * as THREE from 'three';
import * as React from 'react';
import { meshBounds, OrbitControls, useKeyboardControls } from '@react-three/drei';
import { Canvas, ReactThreeFiber, useFrame } from '@react-three/fiber';
import { AxesHelper } from 'three';


interface MeshProps {
  vertices: number[]; // positions of vertices.
  faces: number[]; // triangle faces
}

function Mesh(props: MeshProps) {


  // https://github.com/pmndrs/react-three-fiber/blob/29a274da73ab01d29ed74bf82768462b04889c50/docs/tutorials/v8-migration-guide.mdx?plain=1#L395-L406
  /*
  <bufferGeometry>
    <bufferAttribute
      attach="attributes-position"
      count={props.vertices.length / 3}
      array={props.vertices} itemSize={3} />
    <bufferAttribute
      attach="attributes-faces"
      count={props.faces.length}
      array={props.faces} />
  </bufferGeometry>
  */

/*
<bufferGeometry>
<bufferAttribute array={indices} attach="index" count={indices.length} itemSize={1} />
<bufferAttribute attach="attributes-position" count={3} array={[1,0,0,0,1,0,0,0,1]} itemSize={3} />
<meshBasicMaterial attach="material" color="blue" />
</bufferGeometry>



<bufferGeometry>
<bufferAttribute array={[0, 1, 2]} attach="index" count={3} itemSize={1} />
<bufferAttribute attach="attributes-position" count={3} array={[0, 0, 0, 2, 0, 0, 0, 2, 0, 2, 2, 0, 0, 0, 2]} itemSize={3} />
<bufferAttribute attach="attributes-normal" count={3} array={[0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, ]} itemSize={3} />
</bufferGeometry>
*/

/*
<bufferGeometry>
<bufferAttribute array={[0, 1, 3, 1, 2, 3, 0, 1, 4, 1, 2, 4, 2, 3, 4, 3, 0, 4]} attach="index" count={3} itemSize={1} />
<bufferAttribute attach="attributes-position" count={5} array={[-2, 0, 0, 2, 0, 0, 2, 2.25, 0, -2, 2, 0, 0, 0, -5]} itemSize={3} />
</bufferGeometry>
*/

/*
    <bufferGeometry>
    <bufferAttribute attach="attributes-position" count={3} array={[-5, -5, 5, 5, -5, 5, 5, 5, 5]} itemSize={3} />
    </bufferGeometry>

    <boxGeometry args={[5, 5, 5]}></boxGeometry>
*/
  // const vertices = [2, 0, 0, 0, 2, 0, 0, 0, 2];
  // const indices = [0, 1, 2];

  /*
   const nverts = 500;
  const positions = new Float32Array(nverts * 3);
  for (let i = 0; i < nverts; i++) {
    if (i % 3 == 2) { positions[i] = 0; }
    else {
      positions[i] = (Math.random() - 0.5) * 10;
    }
  }

  const ntris = 300;
  const index = new Uint16Array(ntris*3);
  for(let i = 0; i < ntris; i++) {
    // index[i] = Math.floor(Math.random() * (nverts - 1))
    index[i] = Math.floor(Math.random() * (nverts - 1));
    index[i+1] = Math.floor(Math.random() * (nverts - 1));
    index[i+2] = Math.floor(Math.random() * (nverts - 1));
    <meshStandardMaterial attach="material" color={"ff0000"}/>
  }
  */

}

/*
const CameraController = () => {
  const { camera, gl } = THREE.useThree();
  useEffect(
    () => {
      const controls = new OrbitControls(camera, gl.domElement);

      controls.minDistance = 3;
      controls.maxDistance = 20;
      return () => {
        controls.dispose();
      };
    },
    [camera, gl]
  );
  return null;
};
*/

// use bufferGeometry.
// export default function (props: MeshProps) {
// <OrbitControls />
export default function (props: any) {
  const me = React.useRef<THREE.Mesh | null>(null)
  const geom = React.useRef<THREE.BufferGeometry | null>(null)
  const axes = React.useRef<THREE.AxesHelper | null>(null)
  const [target, setTarget] = React.useState<THREE.Vector3>(new THREE.Vector3(0.1, 0.1, 0.1));
  const [radius, setRadius] = React.useState<number>(0);

  const vertices = new Float32Array(props.vertices.length);
  for (let i = 0; i < props.vertices.length; i++) {
    vertices[i] = props.vertices[i];
  }

  const faces = new Uint16Array(props.faces.length);
  for (let i = 0; i < props.faces.length; i++) {
    faces[i] = props.faces[i];
  }
  
  React.useEffect(() => {
    if (geom.current) {
      // geom.current = geom.current.center();
      geom.current.computeVertexNormals();
      geom.current.computeBoundingBox();
      geom.current.computeBoundingSphere();
      if (geom.current.boundingSphere) {
        setRadius(geom.current.boundingSphere?.radius);
        setTarget(geom.current.boundingSphere?.center);
      }
      axes.current = new THREE.AxesHelper(radius);
      axes.current.translateX(target.x).translateY(target.y).translateZ(target.z);
    }
  }, [props.vertices, props.faces]);

  return <div style={{ height: 300, fontFamily: "monospace" }}>
    <div>ver: '0.0.3' </div>
    <div>target: '{JSON.stringify(target)}' </div>
    <div>radius: '{JSON.stringify(radius)}' </div>
    <div>#Vertices: '{JSON.stringify(props.vertices.length)}' </div>
    <div>#Faces: '{JSON.stringify(props.faces.length)}' </div>

    <Canvas>
      <pointLight position={[150, 150, 150]} intensity={0.55} />
      <ambientLight color={0xffffff} />
      <primitive key={axes.current} object={axes} />
        <mesh ref={me}>
          <bufferGeometry attach="geometry" ref={geom}>
            <bufferAttribute
              attach="index"
              count={faces.length}
              array={faces}
              itemSize={1} />
            <bufferAttribute
              attach="attributes-position"
              count={vertices.length / 3} array={vertices} itemSize={3} />
          </bufferGeometry>
          <meshNormalMaterial attach="material" />
        </mesh>
      <OrbitControls target={target} minDistance={radius*2} />
    </Canvas>
  </div>
}
