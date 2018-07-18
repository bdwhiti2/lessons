//Frankie Lesson 2 (2018-07-18)

/*
Review Tour of UGens
  • In what ways did you experiment with the code provided?
  • What did you learn?
  • What questions do you have?
*/

//SYNTAX pt. 2

// <- THIS IS A SINGLE LINE COMMENT

/*
THIS IS A MULTI-LINE
COMMENT
*/

x = 9 + /*alternatively, you can use this method for an interior comment*/ + 5;

/*
THE SEMICOLON:

In many HLLs (High-Level Languages), white space, carriage returns, and the like are ignored
by the compiler. This is to facilitate the programmer to format their code however they see
fit.

For example:

x = 9.reciprocal + 5 pow: 2;

Can be rendered in any of the following ways (and more!):
*/

x=9.reciprocal+5 pow:2; //Note that there nevertheless MUST be a space between 5 and pow

(
x =
9 . reciprocal
+
5 pow: 2
;
)

/*
Given this flexibility, how does the compiler know where an instruction ends? As you might
already have guessed, the semicolon provides the full stop necessary for the compiler to
take the code preceding it, interpret it into machine language for the CPU to understand,
and then resume interpreting whatever code comes afterward as a new instruction.

Note that SuperCollider is a bit more lenient with regard to semicolon usage compared to
many other languages — specifically it allows for the omission of the semicolon for terminal
lines of evaluated code in functions. That stated, it is still a VERY good idea to get into
the habit of appending a semicolon to every line of code you write, in order to avoid hours
of frantic debugging brought upon by a forgotten, but needed, semicolon. (Not that I'm speaking
from experience, here... ¬.¬)

E.g.:
*/

f = { 7 - 2 }.value //Works (provided nothing comes after it), but not a good habit to get into

f = { 7 - 2 }.value; //A much better habit

f = { 7 - 2; }.value; //The best habit (hard not to make a Sister Act joke here)

/*
Note that it is often considered best practice to insert spaces after curly braces in code.
As mentioned previously, white space like that isn't NECESSARY. The following works just
fine:
*/

f = value{7-2};

f = value { 7 - 2 }; /*<- This ends up being much more readable, however, and really allows for the
                          immediate identification of functions in code*/

//IDE PART 2

/*
If you recall, one has two choices of keystrokes to compile lines of code in the IDE:
Shift-return and command-return. The former is the original method and defaults to executing
one line of code:
*/

x = sin(2) ** cos(5);

/*
To execute multiple lines of code at once, one needs to highlight all of the lines one wishes
to include with the mouse/trackpad prior to hitting shift-return:
*/

x = sin(2)  ** cos(5);
y = tanh(2) ** tan(8);
z = sinh(8) ** sin(3);
f = { x * y * z };
f.value;

/*
To facilitate this process, one can enclose the multi-line code within parentheses and double-click
the opening or closing parenthesis to highlight all of the enclosed code.
*/

(
x = sin(2)  ** cos(5);
y = tanh(2) ** tan(8);
z = sinh(8) ** sin(3);
f = { x * y * z };
f.value;
)

/*
As of SuperCollider 3.5, when the Qt-based IDE was first introduced, a new keystroke combination
for code compilation was introduced: command-return. With command-return, all one needs to do to
execute multiple lines of code is to enclose them in parentheses and make sure the cursor is
somewhere within the interior of the code grouping. The IDE automatically detects what code is
to be compiled without the need for the user to highlight it. (Try the above code group with
command-return now.)

Note that, for code not enclosed in parentheses, command-return functions identically to
shift-return. Furthermore, if there is a mismatch of code enclosures (parentheses, curly
braces, brackets, &c.), command-return will only execute one line of code no matter what
until the problem is corrected.
*/

//ARGUMENTS AND LOCAL VARIABLES

/*
As you no doubt noticed during your romp through SC's 'Tour of UGens', things called 'arg's
and 'var's were declared at the beginning of many of those sound-generating functions.
These refer respectively to 'arguments' and 'variables', both of which possess similar, yet
distinct roles in how they work.

*ARGUMENT (arg)*
An argument declared in a function works similarly to the parameters you supplied values
to UGens like VarSaw and SinOsc in the Tour of UGens functions. Arguments are MODULATABLE,
CONTROL RATE VALUES that can perform any number of actions for which one wishes not to
hard-code values; in fact, even if a function you write only has a single purpose in a
composition, it is best to nevertheless supply arguments to ease the reuse of said function
in future musical endeavours. As a brief, non-musical example:
*/

f = { |x, y, z| x ** y / z; };
f.value(3, 3, 3);
f.(9, 2, 37); //shorthand for f.value(args)

/*
NOTE: ARGUMENTS MUST BE DECLARED BEFORE ANYTHING ELSE IN A FUNCTION, IMMEDIATELY AFTER THE
OPEN CURLY BRACE!! THEY MUST ALSO BEGIN WITH A LOWERCASE LETTER (though this can be followed by
any alphanumeric character in any case following).

As you can see, we're piping in values for x, y, and z when we compile the function as opposed
to copy-pasting the function and changing the values manually. This allows for a high degree
of flexibility as functions aren't capable of only returning one value based on hard-coded
information but instead are tiny programs that serve a computational and/or sound-generating
purpose usable for a myriad of distinct applications.

Now, keeping in mind that the homework for next week includes reading up on the dual
server/client halves of SuperCollider, how they relate to each other, and the distinct
roles they play in the sound-generating process, I ask that you for now simply take what
I'm telling you here at face value. The above argument syntax is for NON-SOUND-GENERATING,
CLIENT-SIDE functions only. How arguments are supplied and modulated is different for functions
that return sound-generating code. Nevertheless, it's good to be exposed to this method
sooner than later to prevent confusion down the road (like what happened to me, as
Eli's tutorials don't delve into SC client-side programming at all).

As is the often the case in SuperCollider, there is more than one way to skin a cat, syntactically
speaking, of course. While in the vast majority of my code I've declared arguments in sound-
generating functions similarly to what you see above (that is, between the pipe symbols ||),
recent developments in SuperCollider features in the main development branch — features that
will be added in either 3.10 or 3.11 — have persuaded me to adopt the newer NamedControl method
of argument declaration. The one disadvantage of this method is that it is not universal; it
is entirely for server-side (sound-generating) computation. On the other hand, for our purposes,
that will encompass the vast majority of instances where we will be using arguments, and the
benefits, especially those in development versions of the software, outweigh the disadvantages
of needing to adopt another method of argument declaration for client-side programming.

To illustrate:
*/

s.boot; //If you haven't already, we need to boot the server.

s.meter;

( //Since we will be dealing with multiplpe lines of code, it's best to enclose them in parentheses
x = {
	[ //As this sound will involve both left and right channels, we need to engage in multichannel expansion (see below)
		SinOsc.ar(\freq1.kr(880), 0, LFPulse.kr(\rate1.kr(0.5), 0,   \width1.kr(0.1), \amp1.kr(0.2))),
		SinOsc.ar(\freq2.kr(880), 0, LFPulse.kr(\rate2.kr(0.5), 0.5, \width2.kr(0.1), \amp2.kr(0.2)))
	];
}.play;
)

/*
As you can see, we are now supplying NamedControls — IOW, modulatable values that possess distinct
(and ideally descriptive) names to which they can be referred outside of the function — as the parameter
values for both our sound-generating sine wave oscillators and their respective controlling
low-frequency pulse generators. We also give each NamedControl a streaming rate and a default
value, the latter not strictly being necessary (but very handy to supply!).

Getting tired of the hospital-esque beeping yet? Let's alter some values!
*/

x.set(\rate1, 1, \rate2, 1); //Here we're setting the rates at which both LFPulse UGens generate their pulses to 1Hz

x.set(\width1, 0.05, \width2, 0.05); //Now we're tightening their widths by half

x.set(\width1, 0.5); //Altering the width of the first LFPulse only to half a second

x.set(\freq1, 440); //Changing the pitch of the first SinOsc to be an octave lower

x.release;

/*
A brief note about streaming rates of NamedControl/argument values: they refer to the rate at which
the values themselves are updated by the system; they have NOTHING to do with the sound production
themselves! \freq1 and \freq2 can both be control rate as there's no need to have the system keep
up with their values at the audio rate. This of course is different when dealing with granular
synthesis — an audio rate control is necessary if one wants sample-accurate synthesis — as well
as piping in audio signals from elsewhere.

Also, keep in mind that the NamedControl method of declaring arguments is a fairly recent addition
to the world of SuperCollider. While I encourage its use for your own code (for reasons that will
be made quite clear in future lessons), you should nevertheless be familiar with how the above
would be rendered in functional argument notation, as that kind of code is still by-and-large
much more commonly run across:
*/

(
x = { |freq1=880, freq2=880, rate1=0.5, rate2=0.5, width1=0.05, width2=0.05, amp1=0.2, amp2=0.2|

	[
		SinOsc.ar(freq1, 0, LFPulse.kr(rate1, 0,   width1, amp1)),
		SinOsc.ar(freq2, 0, LFPulse.kr(rate2, 0.5, width2, amp2))
	];
}.play;
)

/*
As you can see, the arguments are all housed between the pipe (||) symbols seen above
in the client-side syntax. However, the .set method is still used to modulate arguments
on the fly (NOT .value!), with the exact same syntax as used for NamedControls.

e.g.:
*/

x.set(\freq2, 1320, \rate1, 1.25, \amp2, 0.1);

x.release;

/*
Finally, one can still infrequently find staunch proponents of the old SuperCollider 2 method
of argument notation. Notice that its behavior is identical to the piped || way of doing things;
the only differences are the use of the 'arg' tag instead of || and the appending of a semicolon
upon the conclusion of argument declaration:
*/

(
x = { arg freq1=880, freq2=880, rate1=0.5, rate2=0.5, width1=0.05, width2=0.05, amp1=0.2, amp2=0.2;

	[
		SinOsc.ar(freq1, 0, LFPulse.kr(rate1, 0,   width1, amp1)),
		SinOsc.ar(freq2, 0, LFPulse.kr(rate2, 0.5, width2, amp2))
	];
}.play;
)

/*
I tend to prefer pipes instead of the arg tag as I find the former helps the arguments stand out
from the locally-declared variables (see below), thus avoiding confusion, but YMMV.

*LOCAL VARIABLES (var)*

Up until now we've made use of what are known as 'interpreter variables' in SuperCollider. They
are very similar to what are known as 'global variables' in other programming languages, with
a number of exceptions:

• They are already pre-declared by the interpreter.
• They are valid for as long as the interpreter is running.
• They can only be a single letter of the alphabet, and as such
• There are only twenty-six of them (a~z).

The second point is particularly important to grasp, as it means that any values set to
interpreter variables remain in memory until either they are cleared by another program
or the interpreter is reset/the user quits SuperCollider. This means that one can run
into conflicts if one does not fastidiously define one's interpreter variables at the start
of their code. Furthermore, interpreter variables, just like global variables in other languages,
open the code up to potential memory leaks and exploitation, and with only 26 at one's disposal
one runs out of them quite quickly.

Thankfully, like any HLL SuperCollider comes equipped with the ability to declare variables
local to a chunk of code. These are typically declared within functions,

e.g. x = { var aThing = someCode.kr; };

but occasionally one can find a use to assign local variables to multiple functions, like so:
*/

(
var aValue = 42;

x = { |anArg| aValue + anArg };
y = { |anArg| aValue + anArg };

x.(18) * reciprocal(y.(23));
)

/*
Where aValue is shared between the two functions while each function's anArg is exclusive
to itself.

As seen above, local variables are declared with the 'var' tag. They must follow arguments
(though NOT NamedControls!) but precede any other code found in a function. Like arguments,
local variables can be named as descriptive words, so long as they begin with a lowercase
letter. They can be assigned values at declaration, or only have their names declared with
the intent of using them later. In fact, until you gain more familiarity with the language,
I highly recommend declaring variables WITHOUT assigning them values first, preferably grouping
like processes together when doing so, and then assigning their values when they become relevant
in your code.

(Don't worry if you don't understand what's going on below. Both of these examples come from
my most-recently premiered piece, and will be explored in greater depth during the coming weeks.)
*/

(
x = {
	var numPartials, numChannels;
	var env, sig;

	numPartials = 10;
	numChannels = 5;
	env = EnvGen.kr(Env.sine(\rate.kr(15)), levelScale: 0.06, doneAction: Done.freeSelf);
	sig = Klang.ar(`[ { { rrand(333.0, 777.0)}.dup(numPartials) }.dup(numChannels), nil, nil]);

	Splay.ar(sig * env, center: 1.0.rand2) * \amp.kr(1);
}.play;
)

/*
Local variables can also refer to themselves recursively, as can be seen in the following code:
*/

(
x = {
	var numPartials, numChannels;
	var env, sig;
	var feedback;

	numPartials = 20;
	numChannels = 5;
	env = EnvGen.kr(Env.sine(15), levelScale: 0.06, doneAction: Done.freeSelf);
	sig = Klang.ar(`[ { Array.fill(numPartials, { 38.midicps * Rand(1, 40).round(0.5) }) }.dup(numChannels), nil, nil]);

	feedback = LocalIn.ar(2);
	feedback = OnePole.ar(feedback, 0.4);
	feedback = OnePole.ar(feedback, -0.08);
	feedback = Rotate2.ar(feedback[0], feedback[1], 0.2);
	feedback = DelayN.ar(feedback, 0.25, 0.25);
	feedback = LeakDC.ar(feedback);
	feedback = ((feedback + sig) * 1.25).softclip;

	LocalOut.ar(feedback);

	Splay.ar(feedback * env, center: 1.0.rand2) * \amp.kr(0.1);
}.play;
)

/*
What's happening here is that the feedback variable continues calling upon itself from lines
351 through 357, each time setting itself to the result of the operation being performed upon
it.

HOMEWORK FOR NEXT LESSON:
• Shift-command-D 'Client vs Server', 'Server Guide', and 'Server Architecture' (without quotes) and read all three.
• Take at least five different functions in the 'Tour of UGens' and rewrite them using
  NamedControls. Try modulating your controls with the .set method!