# zisnake - A simple snake game made in Zig

zisnake is a very simple snake game made in Zig. It's purpose was not to be a full-fledged snake clone, but a simple game/project where I could learn the basics of both Zig and raylib.

## Demo

https://github.com/user-attachments/assets/e581e995-73ad-416e-bd52-81f89b4c9923

https://github.com/user-attachments/assets/6153de24-45ff-401b-a505-c63852ef786f



## Purpose
The purpose of this project, as mentioned above, was for me to learn Zig and [raylib](https://www.raylib.com).

Game dev is something I've always been passionate about, but hadn't done it in a while, and I always used a game engine (Unity, Unreal Engine, ...) to do my game dev. So this project can also be seen as me coming back to game dev, but doing it from scratch.

And, another reason is that recently, with all the AI bullsh*t I felt like I needed a small project where I forced myself to not use AI and sort of wake up the wonder of building again and have fun. It was amazing, specially dealing with bugs, feeling like you are lost and can't find a way for things to work like you want them to, and then, it just clicks. I don't think anything will ever beat that feeling.

## Stack

zisnake is built using Zig 0.16.1 and [raylib](https://www.raylib.com).

## How to play

To play zisnake, you must first install raylib on your machine. For mac users:

```bash
brew install raylib
```

Once you have raylib installed on your machine, you should clone the `zisnake` repo and run the code with:

```bash
zig build run
```

This will open the game window.

To move the character you should use the arrow keys (up, down, left and right). Once you see the game over screen, you can press `r` to restart the game.

And that's it. That's the whole game.

## Limitations

As the purpose of this project wasn't to make a full-fledged snake clone, somethings are different or just don't work as they are supposed to. For example, you can lose the game by turning back and going through your own body:

https://github.com/user-attachments/assets/e09c4785-ba90-4281-8260-6a7b1dbc10f5

This happens because the movement in _zisnake_ is done pixel by pixel, which is not the "snake" way of doing things.

There's more limitations, like for example, you can only restart the game after you have actually collided with yourself (game over condition), which is not necessarily bad, but it makes so the players have to force a game over to restart.

There's also no way of keeping a high score currently. This wouldn't be a very hard thing to implement, it could be as simple as a text file that just keeps the high score, but, it just wans't in my "stuff to learn/do list".
