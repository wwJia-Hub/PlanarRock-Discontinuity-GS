function [final_index,final_class,indices_normals,indices_area,vertices,faces,normals]=compute(fn,a0,b0,min_component_size)
mesh=readMesh_ply(fn);
vertices=mesh.vertices;
faces=mesh.faces;

faceAreas = meshFaceAreas(vertices, faces);
normals = meshFaceNormals(vertices, faces);
mesh_size = length(faces);