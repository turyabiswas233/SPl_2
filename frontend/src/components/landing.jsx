import { useEffect, useRef } from "react";
import gsap from "gsap";
import { ScrambleTextPlugin, ScrollTrigger, ScrollSmoother } from "gsap/all";

gsap.registerPlugin(ScrollTrigger, ScrollSmoother, ScrambleTextPlugin);
const TestAnime = ({ text }) => {
  const containerRef = useRef(null);

  useEffect(() => {
    const tl = gsap.timeline();
    tl.add(animeText());
  }, []);

  function animeText() {
    return gsap.fromTo(
      containerRef.current,
      {
        duration: 14,
        ease: "sine.in",
        scale: 0,
        y: -100,
        scrambleText: {
          text: ".",
          speed: 1,
        },
      },
      {
        duration: 4,
        ease: "power2.out",
        y: 0,
        scale: 1,
        scrambleText: {
          text: text,
          speed: 1,
          revealDelay: 0.2,
        },
      }
    );
  }

  return (
    <h1
      id="pin-windmill-svg"
      className="poppins-bold text-center text-pmv w-auto logo-right-blink text-7xl"
      ref={containerRef}
    >
      .
    </h1>
  );
};
function Landing() {
  return (
    <div className="w-full h-dvh flex justify-center items-center flex-col">
      <TestAnime text={"Dromos"} />
      <p className="text-center text-black">Smart Simple Sustainable</p>
    </div>
  );
}

export default Landing;
