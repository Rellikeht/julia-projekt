module Lights

using Objects, Vectors
import CairoMakie: RGBf

export Ray, Frange
export march
export BLACK, DEFAULT_DISTANCE_LIMIT, DEFAULT_REFLECTION_LIMIT

const Frange = StepRangeLen{Float64,Float64,Float64,Int}

const DEFAULT_DISTANCE_LIMIT = 0.01
const DEFAULT_REFLECTION_LIMIT = 1
const BLACK = RGBf(0.0, 0.0, 0.0)

mutable struct Ray
    position::Vect
    direction::Vect
end

function *(c1::RGBf, c2::RGBf)::RGBf
    RGBf(
        c1.r*c2.r,
        c1.g*c2.g,
        c1.b*c2.b,
    )
end

function shadowRay(
    scene::Scene,
    position::Vect,
    light::LightSource,
    distance_limit::Float64=DEFAULT_DISTANCE_LIMIT,
)::RGBf
    dir::Vect = direction(position, light.position)
    ray::Ray = Ray(position + distance_limit * dir, dir)

    while inside(scene.bounds, ray.position)
        d::Float64 = lightSdf(scene, ray.position)
        if d < distance_limit
            closest = lightClosestElement(scene, ray.position)
            if closest == light
                # TODO distance scaling
                return light.intensity * max(
                    0,
                    ray.direction * normal(closest, ray.position)
                )
            else
                return BLACK
            end
        end
        ray.position += d * ray.direction
    end

    return BLACK
end

function march(
    scene::Scene,
    ray::Ray;
    reflection_limit::Int=DEFAULT_REFLECTION_LIMIT,
    distance_limit::Float64=DEFAULT_DISTANCE_LIMIT,
)::RGBf
    if reflection_limit < 0
        return BLACK
    end

    #     BOX_SIZE::Float64 = distance(
    #         scene.bounds[1],
    #         scene.bounds[2]
    #     )
    #     STARTING_POSITION::Vect = ray.position

    while inside(scene.bounds, ray.position)
        d::Float64 = sdf(scene, ray.position)
        if d < distance_limit
            norm = normal(scene, ray.position)
            shadow_ray_color = shadowRay(
                scene,
                ray.position,
                scene.lights[1],
                distance_limit
            )

            #             reflected = march(
            #                 scene,
            #                 Ray(
            #                     ray.position,
            #                     reflect(norm, ray.direction)
            #                 );
            #                 reflection_limit=reflection_limit - 1,
            #                 distance_limit=distance_limit
            #             ) # * color

            # return RGBf(0.5 + norm[1] / 2, 0.5 + norm[2] / 2, 0.5 + norm[3] / 2)
            return shadow_ray_color
            # return reflected / 2 + shadow_ray_color / 2
            # return RGBf(distance(STARTING_POSITION, ray.position) / BOX_SIZE * 2)
        end
        ray.position += d * ray.direction
    end

    return BLACK
end

function march(
    scene::Scene,
    resolution::Tuple{Int,Int}=(640, 480);
    reflection_limit::Int=DEFAULT_REFLECTION_LIMIT,
    distance_limit::Float64=DEFAULT_DISTANCE_LIMIT,
)::Matrix{RGBf}
    _, ymin, zmin = scene.camera.imagePlane.down_left
    _, ymax, zmax = scene.camera.imagePlane.top_right
    colors::Matrix{RGBf} = zeros(resolution[1], resolution[2])
    i::Int = 1

    for z in Frange(zmin:(zmax-zmin)/(resolution[2]-1):zmax)
        for y in Frange(ymin:(ymax-ymin)/(resolution[1]-1):ymax)
            p::Vect = Vect(scene.camera.imagePlane.top_right[1], y, z)
            colors[i] = march(
                scene,
                Ray(
                    scene.camera.position,
                    direction(scene.camera.position, p),
                );
                reflection_limit,
                distance_limit,
            )
            i += 1
        end
    end

    return colors
end

let
    psolid = [
        Solid(Sphere(Vect(1, 2, 3), 2.0)),
        Solid(Cube(Vect(4, 5, 6), 3.0))
    ]

    pcam = Camera()
    pscene = Scene(
        pcam,
        DEFAULT_WORLD_BOUNDS,
        [LightSource(Vect(3, 2, 0))],
        psolid
    )

    _ = march(pscene, Ray((0, 0, 0), (1, 0, 0)); reflection_limit=1)
    _ = march(pscene, Ray((0, 0, 0), (1, 1, 0)); reflection_limit=2)
    _ = march(pscene, (20, 10); reflection_limit=3)
end

end
