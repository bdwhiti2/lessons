//Frankie Lesson 5 (2018-08-08)

//1: Go over HW
//2: Envelopes
//3: Allocating, Writing to, and Reading from Buffers

//ALLOCATING, WRITING TO, AND READING FROM BUFFERS

s.boot;

/*
Let's return to the buffer allocated last week:
*/

b = Buffer.alloc(s, 4096, 1);

/*
What do the arguments mean, you might ask? Well, 's' refers to our server, '4096' to the number
of *FRAMES* (important to distinct frames from samples, as they are not always interchangable!),
and 1 to the number of channels being asked for. Thus, this is a chunk of RAM that will house
4096 frames of a monophonic signal. This is a really short chunk of audio; if the sample rate is
44100, then this buffer will only contain just under a tenth of a second of audio. This is fine
for a periodic waveform fed through Osc, but not particularly helpful for most live audio input
applications.

Let's say you want to allocate a buffer that can house up to five seconds of monophonic audio
at a 44100Hz sample rate. This can be accomplished by the following:
*/

b = Buffer.alloc(s, 220500, 1);
//The '1' is technically optional as .alloc defaults to 1 channel here, but it is nevertheless
//a good habit to get into to declare precisely how many channels you want to contain in any
//given buffer.

/*
Of course, you don't have to do the math yourself, you can keep the multiplication intact:
*/

b = Buffer.alloc(s, 5 * 44100, 1);

/*
That's great, but what about when you're using someone else's audio interface set to 48KHz?
Or 96KHz? Especially during a performance, you won't have the opportunity to reset everything
just to get the sample rate you prefer, but leaving the code like this with a hard-coded
numFrames value won't net you the five seconds of buffered audio you need, either. You can,
of course, alter the multiplicand to whatever value fits the sample rate you need, but this
is cumbersome to do every time and may lead to mistakes due to oversight at some point.
Thankfully, SuperCollider has a method that will save you undue headache in this regard:
*/

b = Buffer.alloc(s, 5 * s.sampleRate, 1);

/*
.sampleRate will automatically poll whatever the current sample rate of the booted server is,
thus ensuring accuracy.

Now that we know how to allocate buffers, how do we write to them? SuperCollider gives us
two very similar UGens to choose from to accomplish this: RecordBuf and BufWr. Superficially,
these two seem very similar to each other, but there is one fundamental difference: RecordBuf
(along with its counterpart PlayBuf) progresses through the buffer linearly, allowing the
programmer to modulate only the rate at which data is written to the buffer*, while BufWr (and BufRd)
allows the programmer to directly modulate the position within the buffer at which the pointer
resides. In other words, to get from frame 514 to 4092 using RecordBuf, one will need to scrub
through the intervening frames somehow, whereas BufWr will enable one to jump directly to
4092, leaving the intervening frames untouched.

* One can make some clever use of triggers to return RecordBuf's pointer back to the beginning
of the buffer, but that's about as much as you can do with regard to non-linear recording with
that UGen.

This results in RecordBuf being ultimately easier to use and BufWr more powerful, even if
cumbersome. However, I will start by using RecordBuf as not only is it easier to learn, I
find myself using it 90% of the time. (I find recording linearly and playing back chaotically
ultimately easier to accomplish without pops and just as effective in the end.)

Let's now capture five seconds of our own voice! Note that here we do NOT want to use { }.play,
or even an Out UGen, as we don't want to directly monitor our input.
*/

(
SynthDef.new(\record, {
	var sig, env;

	sig = SoundIn.ar(0);
	env = EnvGen.kr(Env([0, 1, 1, 0], [0.1, 4.8, 0.1]), doneAction: Done.freeSelf);

	RecordBuf.ar(sig * env, \bufnum.kr(b), loop: 0);
}).add;
)

x = Synth.new(\record);

/*
And now let's play it back!
*/

x = { PlayBuf.ar(1, \bufnum.kr(b), \rate.kr(1) * BufRateScale.kr(\bufnum.kr), doneAction: Done.freeSelf) }.play;

/*
Let's dissect the usage of both RecordBuf and PlayBuf here. In RecordBuf, we are specifying
the following parameters:

inputArray: the signal which is being fed into the buffer
bufnum    : the ID of the target buffer
loop      : Whether or not the recorder perpetually resets to frame 0 once the last frame of the
            buffer is reached (0 for off, 1 for on)

There are other arguments, but we'll cross that bridge when we get to it.

Into PlayBuf we are feeding:

numChannels: Number of channels of the buffer. This cannot be modulated post-compilation!
bufnum     : the ID of the bufnum that we're playing back
rate       : the rate at which the buffer is being played back, at rate * s.sampleRate.
             Note the BufRateScale UGen; this ensures that the rate of playback will always
             be relative to the *current* server sample rate, NOT the original sample rate
             used for the buffer. (This is typically not needed for playing back buffers
             recorded in the same session, as the server's sample rate cannot be modulated
             while booted anyway. Nevertheless, it's a good habit to get into, as I have been
             stumped by improper playback speeds of prerecorded audio on more than one occasion,
             stemming from forgetting to include the BufRateScale multiplicand!)

Again, there exist other arguments (including loop), but we'll go over them as needed.

We can rewrite both the record and playback Synths using BufWr and BufRd, respectively. As I
find BufRd more practically useful than BufWr, let's stick to that for now:
*/

(
x = {
	var pos = Phasor.ar(\trig.kr(0), \rate.kr(1) * BufRateScale.kr(\bufnum.kr(b)), 0, BufFrames.kr(\bufnum.kr));

	BufRd.ar(1, \bufnum.kr, pos, \loop.kr(0), \interp.kr(4));
}.play;
)

/*
Whoa, that's a lot more code for the same result! Well, ALMOST the same result; despite specifying
the loop parameter of BufRd to default to 0, the buffer is nonetheless looping!

Here is where BufRd gets a little complicated. The loop functionality only determines whether
or not the buffer loops if the phasor goes out of range. For instance:
*/

(
x = {
	var pos = Phasor.ar(\trig.kr(0), \rate.kr(1) * BufRateScale.kr(\bufnum.kr(b)), 0, BufFrames.kr(\bufnum.kr) + (2 * SampleRate.ir));

	BufRd.ar(1, \bufnum.kr, pos, \loop.kr(0), \interp.kr(4));
}.play;
)

/*
With loop set to 0, we have an extra 2 seconds of silence before the buffer resets, as the
Phasor is set to provide index values up to 7 * s.sampleRate. But with loop set to 1:
*/

(
x = {
	var pos = Phasor.ar(\trig.kr(0), \rate.kr(1) * BufRateScale.kr(\bufnum.kr(b)), 0, BufFrames.kr(\bufnum.kr) + (2 * SampleRate.ir));

	BufRd.ar(1, \bufnum.kr, pos, \loop.kr(1), \interp.kr(4));
}.play;
)

/*
The remaining two seconds are filled with the first two seconds of the recorded buffer before
the phasor resets.

If one only wants to play through a buffer only once using BufRd, one way to do it is through
the following:
*/

(
x = {
	var dur, pos;

	dur = BufFrames.kr(\bufnum.kr(b)) / SampleRate.ir;
	pos = Line.ar(0, BufFrames.kr(\bufnum.kr) * BufRateScale.kr(\bufnum.kr), dur, doneAction: Done.freeSelf);

	BufRd.ar(1, \bufnum.kr, pos, \interp.kr(4));
}.play;
)

/*
(The loop argument doesn't matter as the Line frees the Synth once it finishes.)

There are of course more elegant ways to go about doing this. Can you think of at least one?

<...>

I prefer BufRd over PlayBuf thanks to the limitless options available to one for modulating phase.
You can use quite literally ANY audio rate signal!
*/

(
x = {
	var pos = LFTri.ar(0.1) + LFTri.ar(0.23) * BufFrames.kr(\bufnum.kr(b) * BufRateScale.kr(\bufnum.kr));

	BufRd.ar(1, \bufnum.kr, pos, 1, \interp.kr(4)); //I'm not even bothering to assign to loop a namedControl at this point
}.play;
)

(
x = {
	var pos = LFNoise1.ar(0.5) * BufFrames.kr(\bufnum.kr(b));

	BufRd.ar(1, \bufnum.kr, pos, 1, \interp.kr(4)); //I'm not even bothering to assign to loop a namedControl at this point
}.play;
)

/*
IN-CLASS ASSIGNMENT: Write a simple Synth that will allow you to play a buffer back while controlling
the rate of playback via the X axis of the mouse. (BONUS: let the Y axis control amplitude!)

HW:
<...>