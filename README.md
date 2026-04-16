# README

A hobby project to help me learn computer graphics by connecting it to a passion of mine: running.
This project aims to reignites the fire in me for running, programming and art. How, you might ask. The answer is simple, by tring to have fun with them all. :)

# r u n i

**Discover the joy and beauty of running and the marvels of belonging and powers of contributing to a community.**

Running is an art, every run is unique and most runs should be fun. That’s key for longevity, not just for running, but also for life.

As humans we need and thrive in communities. It gives us the sense of belonging, safety, support and purpose.

## Vision

A place where runners can have fun with their metrics instead of analysing them. Where they can create visually pleasing representations which conveys the unique experience they had instead of solely showing how far or how fast they ran. Even rehabilitating runners with slow jogs or even walks could uncover and share the beauty and joy of their sessions.

A place where runners can feel connected to their communities by seeing how their runs contribute to shared animations of group sessions or animations combining the individual runs each club member. Having fun with others and see they collaborate on something bigger than themselves.

## Personal notes

I started running as a means to be fit and healthy. It used to be liberating and made me feel light and happy. It helped me cope and supported me in my life. Until I started focusing on performance way too much and turned running into yet another source of stress.

It’s not to say that chasing performance is bad, but performance can still come while enjoying running. The numbers on the watch only tell a tiny part of the story, and I needed to remind myself to treat them as such.

I often don’t find my place in the world, I feel lost and invisible. Running with others gives me the sense of belonging. It reminds me that we have way more in common than not. We share similar experiences in running as well as in life. This helps me realise I’m never alone.

It’s a revelation that can give one purpose to help others by sharing one’s experience. And it can provide courage to ask for help when one sees others overcoming similar struggles. 

This is how individuals impact the community, just by being themselves. And this is how the community impacts individuals, just by connecting each other.

Seeing others blast out PBs on races or finishing an outstanding session on the track while I’m being injured is miserable. I admit, seeing their results makes me jealous. But above all, numbers simply don’t communicate the experience of a run.

## App current state

The most significant issue — a must fix before release — is that the visualisations feel detached from the run. The runner needs to feel the connection between the run and the visualisation.

I started creating this app to learn about computer graphics. I’m a novice, not an expert. This means that:
- My creative ideas of possible visualisations are very limited
- The execution of those ideas are poor quality
- I’m slow to add new visualisations

The app itself has the basic functionality implemented, not necessarily with the best UX or most polished and performant UI:
- Fetching runs from Strava or import GPX or runi files
- Run pre-processors to decide how to use the data in the visualisation engine
- Select between 2 visualisations that driven by the runs, and can be further adjusted with some visualisation specific controls.
- Export visualisation as a video or runi file.

## App future features

- Multi-run visualisations (**MRV**)
    - “stack” runs on each other: for example to be able to see how a repeated session would morph a previous one, revealing differences between the two session
    - “concatenate” runs after each other: for example to be able to see a full training week in a single animation
- Collaboration: runners could create a shared animations that combines their runs together to result a single animation
    - “stacked” MRV can be ideal for sessions ran together
    - “concatenated” MRV can be ideal to represent individual sessions of the members of a club
- Groups/ Clubs: basically intrinsic “collaboration” between the members
- Events & Challenges for creating beautiful art by movement.
- More activity tracker integrations: Apple HealthKit, Garmin, Coros, etc
- More advance signal processing and visualisation parametrisation. 
    - The possibility of different processing pipeline for different metrics. 
    - The possibility of choosing the metrics that drive the parameters of the visualisation
- Composable visualisations: combine different kind of visualisation into one animation

## Dani’s principles

If this ever becomes a “thing”, here are my personal principles and north starts.

Name is fixed. It’s called “**r u n i**” - lowercased, characters separated by a single space. I means a lot to me and it doesn’t really matter for anyone else anyway, so it’s **non-negotiable**. In internal docs or messages, “runi” is fine for simplicity, but external communication it’s “r u n i”.

Visualisation should never display the metrics as plain numbers. We should celebrate PBs and other achievements by visually stunning animations, not by admiring numbers.

For individual and collaboration based features should always be free. **Non-negotiable**.
Group & Club feature probably requires a server side that costs money… I’ll see for how long I can finance that, ideally that should also be free for the users.

The code is open source. It started off as a learning project for computer graphics. I’m learning from free resources and it’s my responsibility to give back to the community by letting them learn from the code of visualisations.

App is ad free. No banners. If it attract brands, a brand sponsorship should be well integrated as a custom seamlessly integrated visualisation. No labels, no text. The visualisation should be able to convey the sponsored brand.

A social media profile of the app should not try to sell it by explaining the app via words or catchphrases, definitely not copying “trends”. It should be by sharing exported animations from the app, based on real runs. If the product is good and have a high quality it will find the people who into this. Not everyone will be and that’s fine. An even better “marketing strategy” is resharing animations that the app users shared on social media.



# Learning materials

- https://iquilezles.org/articles/
