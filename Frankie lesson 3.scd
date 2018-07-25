//Frankie Lesson 3 (2018-07-25)

//1: Go over HW from last lesson
//2: Not All Interpreter Variables are Made Equal: the Interpreter Variable 's'
//3: Intro to SynthDefs
//4: Routing Audio I

//NOT ALL INTERPRETER VARIABLES ARE MADE EQUAL: THE INTERPRETER VARIABLE 'S'

/*
Last week we discussed briefly about interpreter variables. These are single-letter variables
that do not need to be declared via a 'var' tag and which are effectively global in reach
— in that all functions, objects, dictionaries, &c. inherit their usage and, at the same time,
can set a new value to the variables, making them convient, yet potentially dangerous if
mishandled, devices.

By default, all interpreter variables initialize to 'nil' save one: s. s is initialized to
point to Server.default, which defaults to the local server (if you remember from your reading,
SC has two initially-declared servers: local (networked via 'localhost' over port 57110) and
internal (not networked at all)). This is why we've never had to set s in our code, why s.boot
"just works":
*/

s.boot; //boots the default server despite not having Server.default being specifically set to it

s.quit; //quits the default server

/*
Keeping in mind how interpreter variables behave, what danger is implicit in this?

<...> //from here on, I'll use this to denote when the answer will be sought after during our lesson
*/

//INTRO TO SYNTHDEFS

/*
So far we've generated audio by inserting code between two curly braces and appending (or prepending,
depending on choice of syntax) a 'play' message. However, this is what's known in SuperCollider as
a "convenience method"; that is, this syntax facilitates the generation of sound using a familiar
syntactic structure but is not wholly indicative of what is going on under the hood.

Let's return to our "Hello, World!" example from our first lesson:
*/

x = { LFTri.ar(440, mul: 0.2) }.play;
x.release;

/*
This is what is actually being compiled when you evaluate 'x' above (with slightly
expanded formatting using local variables to facilitate comprehension):
*/

(
SynthDef.new(\temp0, { //altered name slightly to prevent potential conflicts
	var env, sig;

	env = Linen.kr(\gate.kr(1), releaseTime: \fadeTime.kr(0.01), doneAction: Done.freeSelf);
	sig = LFTri.ar(440, mul: 0.2);

	Out.ar(\out.kr(0), sig * env);
}).add;
)

x = Synth.new(\temp0);

//x.release maps to the following:
x.set(\gate, 0);
//though x.release still works as intended for Synth.new

//Let's take a closer look at what is going on here:

(
SynthDef.new(\temp0, //Here we are declaring a new "SynthDef" and calling it 'temp0' (either \temp0 or 'temp0' works)
	{ //This begins what is called the 'ugenGraphFunc(tion)', a function containing what is necessary to generate audio
	var env, sig;

		//If you recall, I recommended the usage of the 'release' method over 'free' since 'free'
		//ignores the envelope automatically applied to { }.play. The following is the envelope
		//that SC injects to that convenience method, as a SynthDef itself has no inherent envelope
		//(Envelopes will be discussed in greater detail below)

		env = Linen.kr(\gate.kr(1), releaseTime: \fadeTime.kr(0.01), doneAction: Done.freeSelf);

		//Now we can finally get to the meat of our audio synthesis!
		sig = LFTri.ar(440, mul: 0.2);

		//But wait... we're not done! While { }.play automatically sends the last computed value
		//over our default hardware output bus, SynthDef does not have such functionality
		//built into it. What { }.play does to achieve this result is to add what is called an
		//Out UGen, which we will do now:

		Out.ar(\out.kr(0), sig * env); //Here we are outputting over bus 0 the signal, to which the envelope is applied
}).add; //Now we are adding the above Synth definition to the SynthDef library (SynthDescLib) for later use...
)

x = Synth.new(\temp0); //...which happens to be right now!

/*
As you can no doubt see, this is a LOT more code than what we used for our "Hello, World!"
example. Furthermore, it's to apparently very little benefit: as you can see in the server
widget on the bottom right of the screen, the { }.play convenience method makes use of 9 UGens
while the SynthDef approach uses 8. Hardly a useful optimization in the long run, and for what
keystroke cost!

IN-LESSON CHALLENGE: Take the following sound-generating function, transcribe it into a
SynthDef, play it and release it without popping. (REQUIRES SC3-PLUGINS)
*/

(
x = {
	Gendy4.ar(
		ampdist: 0,
		durdist: 1,
		adparam: 1,
		ddparam: 1,
		minfreq: \freq.kr(380.84) - 10,
		maxfreq: \freq.kr + 10,
		ampscale: \ampScale.kr(0.05),
		durscale: \durScale.kr(0.05),
		initCPs: 24,
		knum: \c_points.kr(12),
		mul: \amp.kr(0.02)
	).dup;
}.play;
)

//ROUTING AUDIO I

/*
So if the SynthDef approach to audio synthesis is so relatively laborious to type, why use it?
Why even learn it?

To answer the first question, there is a significant portion of the SuperCollider programming
language that relies heavily on SynthDefs: Patterns, a programming convention that lies at the
core of the language's algorithmic compositional functionality. Therefore, if you ever want to
dabble in algorithmic sound computation via SC, you cannot avoid constructing SynthDefs.
There are other good reasons to use SynthDefs (iteration in particular benefits strongly
from the use of these constructs), but suffice to say you can get by quite nicely using
little but { }.play for sound synthesis, and VERY nicely using something called JITLib
(which will be a primary focus of our lessons from a class or two down the road and onward).

Why are we constructing SynthDefs now, though? It's because they force the student to come to
terms with how audio routing, or "bussing", in SuperCollider works, something which can be
very easily taken for granted using other programming conventions in SC but which can throw
the uninitiated for a loop if a routing conflict arises and one cannot figure out a) why
the audio isn't outputting what one expects, much less b) how to go about fixing it.

In computer science, a "bus" is an electrical wire upon which binary data is transmitted from
one part of the CPU to another. This definition is retained in electroacoustic music, though
what is "bussed" in an analogue mixer is not binary data, rather an analogue representation
of an acoustical waveform as continuous voltage. Of course, digital mixers and any digital audio
programming language/workstation subscribe to the computer-science definition, but it can
nevertheless be helpful to think of bussing as a combination of both approaches, as while
digital audio is binary data it nevertheless serves a different purpose — and is streamed at
a different rate — than data used to modulate parameters of a sound-generating UGen.

<...> Doctor's appt so the rest will be filled in during the lesson

NEXT LESSON:

• Routing Audio II
• Writing to and Reading from Buffered Memory

HOMEWORK:

• Read the Wikipedia article on Filter (Signal Processing): https://en.wikipedia.org/wiki/Filter_(signal_processing)

• Using the SynthDef approach, design two sounds that make use of SUBTRACTIVE SYNTHESIS. Use at
  least two filters in each SynthDef, with one of the following UGens as a source sound:
    • WhiteNoise
    • PinkNoise
    • BrownNoise
    • Impulse
    • LFPulse
    • Dust