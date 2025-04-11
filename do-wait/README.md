# ![do-wait icon](./src/icon.svg) Do Wait

Inspired by [this article](https://error454.com/2017/03/09/the-death-of-tick-ue4-the-future-of-programming/)


This is the API described in the article:
```
3._do
[
  fire_projectile(1.0)
  _wait(0.05)
]
_wait(0.3)
100.do
[
  fire_projectile_degrees([360.0 / 100.0] * idx>>, 1.0)
]
_wait(1.0)
```

Using GDScript, it could look something like this:

```gdscript
func _ready():
    Do.do([
        Do.do([
            func(): fire_projectile(1.0),
            Do.wait(0.05)
        ])
        Do.wait(0.3)
        Do.do([
            func(idx): fire_projectile_degrees(360.0 / 100.0 * idx, 1.0)
        ])
        Do.wait(1.0)
    ]).execute()
```

This doesn't seem like a very nice API. Can we do better?

**NOTE**: Currently not working at all, running into problems where `await`ed functions don't return. Might be the same problem [this person](https://luiscarli.com/2023/10/06/await-all/) ran into (at the bottom of the article).