# Stage 2 — REST / network probe

> **No beam from any endpoint below** — but read this first:
>
> ⚠️ **Do NOT use `POST /test/cmd/mcu`.** That endpoint executes G-code immediately and
> **bypasses the lid interlock**. It is deliberately absent from this template.
>
> Also: the Vision-generation controller was found with SSH root password login and an
> unauthenticated full-filesystem listing. **Do not put this machine on an untrusted network.**

## My setup

- RNDIS adapter address / subnet:
- Machine IP (usually the gateway of that subnet):
- Sources / lens fitted:

## Port scan

| Port | Open? | What answered |
|---|---|---|
| 22 (SSH) | ☐ | |
| 8080 (REST) | ☐ | |
| 8082 (file listing) | ☐ | |
| other | | |

## Endpoint results

These are the endpoints documented on the **Vision** generation. Whether they survive into the
Ultra is exactly what this stage determines.

### `POST http://<ip>:8080/process/status`

```
<paste response>
```

### `GET http://<ip>:8080/camera/take_photo`

- Returned an image? ☐ yes ☐ no
- Resolution:
- Orientation (rotated? mirrored?):
- **One image, or a composite of two cameras?**  ← this is how we find out how many cameras the Ultra really has

### `GET http://<ip>:8080/device/camera/download`

```
<paste the calibration JSON, or its top-level structure if it's long>
```

### `GET http://<ip>:8080/device/camera/measure_distance?x=105&y=105`

```
<paste response>
```

- Did the head move? ☐ yes ☐ no
- Values look sane? (Vision returns `{"distance": …, "height-z": …}`; errors return 0 for both)

### Any endpoint suggesting a *second* camera?

<list what you tried and what happened>

## Notes

<anything different from the Vision-generation map — new endpoints, renamed paths, auth required>
