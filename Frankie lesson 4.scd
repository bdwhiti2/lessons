//Frankie Lesson 4 (2018-08-01)

//1: Go over HW
//2: Routing Audio II
//3: Buffers
//4: Wavetable Synthesis

//ROUTING AUDIO II

/*
Continuing from our lesson from last week, it's important to fully grasp precisely how
audio is routed in SuperCollider. For starters, unlike what you may experience while
using some DAWs, there aren't separate mono and stereo busses; in fact, there are technically
no stereo busses at all! All busses in SuperCollider, whether control or audio rate, carry
precisely one stream of data. If it's audio rate, that means it carries one channel of audio.
Control rate busses carry one stream of data.

That being said, this does not mean that SuperCollider requires the programmer to specify
precisely which busses to use for multiple streams of data/multichannel audio. On the contrary,
doing so will only ensure that each stream will be needlessly (and most likely detrimentally)
duplicated. All one needs to do is to specify the *first* bus to be used, and SuperCollider
will automatically expand to however many subsequent streams necessary to stream the entire
array of data.

To illustrate, here our simple monophonic sine wave is being carried over the default audio
output bus (corresponding to the left channel of a stereo setup):
*/

s.boot; //First, we gotta boot the server!
s.meter; //For illustrative purposes, let's pull up the server meter

(
SynthDef.new(\sine, {
	var env, sig;

	env = Linen.kr(\gate.kr(1), releaseTime: \fadeTime.kr(0.01), doneAction: Done.freeSelf);
	sig = SinOsc.ar(mul: 0.2);

	Out.ar(\out.kr(0), sig * env);
}).add;
)

x = Synth.new(\sine);
x.release;

//When we try carrying a stereo signal...

(
SynthDef.new(\sine, {
	var env, sig;

	env = Linen.kr(\gate.kr(1), releaseTime: \fadeTime.kr(0.01), doneAction: Done.freeSelf);
	sig = SinOsc.ar(mul: 0.2).dup; //...as you can see here with the .dup method...

	Out.ar(\out.kr(0), sig * env); //...we still only specify output bus 0...
}).add;
)

x = Synth.new(\sine); //...which nevertheless produces *two* channels of audio
x.release;

//In fact, if one *were* to specify both audio busses in the Out UGen:

(
SynthDef.new(\sine, {
	var env, sig;

	env = Linen.kr(\gate.kr(1), releaseTime: \fadeTime.kr(0.01), doneAction: Done.freeSelf);
	sig = SinOsc.ar(mul: 0.2).dup;

	Out.ar(\out.kr([0, 1]), sig * env);
}).add;
)

x = Synth.new(\sine); //You can see that output bus 1 is carrying double the amplitude of output bus 0...
x.release;

//...because output bus 1 is carrying BOTH the right channel AND a duplicate left channel along the bus!
//We don't see it nor hear it (unless you have a multichannel setup in your home studio), but a
//duplicate right channel IS being carried over output bus 2.

/*
Before we continue, it is imperative to introduce Out's complementary UGen: In. Where
Out enables the outputting of audio or control rate signals, In is how signal is brought
into a Synth. Like Out, it sports both .ar and .kr methods. However, UNLIKE Out, the
programmer MUST specify the number of channels to patch in; SuperCollider has no way
of knowing which signals over which busses should be grouped together.

There is a problem sending everything over bus 0, of course. Let's say one wishes to have
synthesis Synths feed into a ring modulator, processed, and the resulting audio stream
outputted:
*/

(
SynthDef(\triangle, { //Note: in most cases, the .new method can be omitted
	var env, sig;

	env = Linen.kr(\gate.kr(1), releaseTime: \fadeTime.kr(0.01), doneAction: Done.freeSelf);
	sig = LFTri.ar(\freq.ar(333), mul: 0.4);

	Out.ar(\out.kr(0), sig * env);
}).add;

SynthDef(\saw, {
	var env, sig;

	env = Linen.kr(\gate.kr(1), releaseTime: \fadeTime.kr(0.01), doneAction: Done.freeSelf);
	sig = LFSaw.ar(MouseX.kr(200, 800, 1), mul: 0.4);

	Out.ar(\out.kr(1), sig * env); //since we'll be ring modulating both Synths together, we can't have them output to the same bus!
}).add;

SynthDef(\ringMod, {
	var in1, in2;
	var env, sig;

	in1 = In.ar(0, 1);
	in2 = In.ar(1, 1);
	env = Linen.kr(\gate.kr(1), releaseTime: \fadeTime.kr(0.01), doneAction: Done.freeSelf);
	sig = in1 ring4: in2; //of course, in1.ring4(in2) works just as well

	Out.ar(\out.kr(0), sig.dup * env);
}).add;
)

/*
Before we even instance the Synths, what do you expect will happen?
*/

x = Synth(\ringMod);
y = Synth(\triangle);
z = Synth(\saw);

/*
That said, most likely due to habit, I prefer specifying .new for SynthDefs and Synths, so expect
the older format going forward. ;)

<...>
*/

//BUFFERS

/*
A buffer is a "chunk" of Random Access Memory which is reserved for some special purpose. For the
electroacoustic composer, understanding how buffers work is one of the most important tasks.
Typically, our computer's operating system allocates and manages buffers automatically. It's
pretty much how anything gets done, from reading a spreadsheet and displaying it in Excel to
rendering a YouTube video into data us mortals can comprehend. When you're in the programmer's
hotseat, however — and this includes *all* languages, including SC, pd, and Max — the onus
lies on you to make sure an appropriately sized amount of memory is allocated for whatever
you want to do.

Most languages make this an easy task, and SC is no exception. Here you want to use the
Buffer class. From here onward I will reserve the interpreter variable 'b' for buffers,
as that is the convention. That said, you are by no means bound to such a decree, but it
does make things simpler in the long run.
*/

b = Buffer.alloc(s, 4096, 1); //Here we are allocating, or reserving, a chunk of memory suitable for 1 channel of 4096 samples of data

/*
Buffers will soon become your friends. Mastery of them is imperative in *any* language where you
are looking to import data and then use said data for some purpose. One cannot read from disk,
let alone stream data of any type, without putting it in memory where it can be accessed by
whatever process you want to handle said data. If Microsoft has to deal with them with Office,
so should you, haha! ;)

Buffers in SC are necessary for many operations, namely, but not limited to, the importation of
of audio and the storing of periodic wave data for wavetable synthesis. Per your request, we
will handle the latter first:
*/

//Here we are populating the buffer with a periodic, sinusoidal signal complete with six partials.
//Please note that each partial has an amplitude that is 1/n, where n == the number of the partial
//in question. You can of course feel free to use whatever shape you want for your oscillator,
//so long as it is periodic.

b.sine1(1.0 / [1, 2, 3, 4, 5, 6]);

//BRIEF INTERMISSION: SYNTAX III
//Arrays

/*
All HLLs have support for collections of data. These are typically called lists or arrays.
SuperCollider has support for both types (and more!), but for our purposes consider lists
being interchangable with arrays.

Arrays are formatted by having their data enclosed within [] brackets. For instance:

a = [1, 2, 3];

is an array consisting of three objects: the primitive integers 1, 2, and 3, assigned to
the variable (presumably interpreter) 'a'.

An understanding of how Arrays and other sequenceable collections work is arguably even
*more* important than buffers. Feel free to ask questions if you ever find yourself in
any doubt, as they can be tricky.
*/

//WAVETABLE SYNTHESIS

/*
Now that we have our buffer allocated and populated with a periodic signal, we can use that
in our waveshaping exploits.
*/

//Here we are setting up a binaural linerally-interpolating oscillator, using the wave table
//we set up just moments ago:

x = { Osc.ar(\bufnum.kr(b), [80, 80.2], 0, 0.2) }.play;
x.release;

//Here we are populating an array of 32 partials, each with a randomized amplitude,
//and switching it out every quarter of a second until 50 have been produced:

x = { Osc.ar(\bufnum.kr(b), [80, 80.2], 0, 0.2) }.play;

(
{
	var n = 32;

	50.do {
		b.sine1(Array.rand(n, 0, 1).cubed);
		0.25.wait;
	};
}.fork; //The .fork method sets up and plays a Routine in which various time-sensitive events can be scheduled.
)

x.release;

(
Routine {
	var n = 32;

	50.do {
		b.sine1(Array.rand(n, 0, 1).cubed);
		0.25.wait;
	};
}.play; //This is synonymous with the above.
)

/*
Osc is a linerally-interpolating wavetable UGen, but there are others that afford even
greater functionality. Two include VOsc (variable wavetable oscillator) and VOsc3
(three wavetable oscillators).
*/

b = Array.newClear(8);

(
8.do { |i|
	var n, a;

	b[i] = Buffer.alloc(s, 1024);
	n = (i+1) ** 2;
	a = Array.fill(n, { |j| ((n - j) / n).squared.round(0.001) });
	b[i].sine1(a);
};
)

(
x = {
	var mouseX;

	mouseX = MouseX.kr(0, 7);

	VOsc.ar(\bufoffset.kr(0) + mouseX, [120, 121], 0, 0.3);
}.play;
)

x.release;

(
x = {
	var mouseX;

	mouseX = MouseX.kr(0, 7);

	VOsc3.ar(
		bufpos: \bufoffset.kr(0) + mouseX,
		freq1: \freq.kr(240) + [0, 1],
		freq2: \freq.kr      + [0.37, 1.1],
		freq3: \freq.kr      + [0, -0.29],
		mul: 0.3
	);
}.play;
)

x.release;

/*
HW:

Using the skills you've acquired so far, design a palette of five sounds using additive and/or
subtractive synthesis. You don't need to make them SynthDefs; { }.play will be suitable for
this task.