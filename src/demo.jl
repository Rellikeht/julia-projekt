using March, Objects, Vectors
mscene = initMscene(HD)
cam = Camera()

solids = [
    Sphere(Vect(3, 0, 0), 1.5),
    # Sphere(Vect(1, 2, 3), 2.0),
    # Cube(Vect(4, 5, 6), 3.0),
]

scene = Scene(
    cam,
    DEFAULT_WORLD_BOUNDS,
    [LightSource(Vect(2, 3, 0), 2.0)],
    solids
)

render!(mscene, scene)
display(mscene)
