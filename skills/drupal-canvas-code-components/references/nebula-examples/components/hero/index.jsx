import TwoColumnText from "@/components/two_column_text";
import { cva } from "class-variance-authority";

const backgroundVariants = cva("align-center h-full w-full px-8 py-16", {
  variants: {
    darkenImage: {
      false: null,
      true: "backdrop-brightness-75",
    },
  },
});

const Hero = ({
  layout,
  preHeading,
  heading,
  headingElement,
  headingSize = "large",
  text,
  textColor = "dark",
  buttons,
  backgroundImage,
  darkenImage,
}) => {
  return (
    <div
      className="flex min-h-[672px] w-full justify-start bg-cover bg-center bg-no-repeat"
      style={{ backgroundImage: `url(${backgroundImage.src})` }}
    >
      <div className={backgroundVariants({ darkenImage })}>
        <TwoColumnText
          heading={heading}
          headingElement={headingElement}
          headingSize={headingSize}
          layout={layout}
          preHeading={preHeading}
          text={text}
          textColor={textColor}
          buttons={buttons}
          textShadow="medium"
        />
      </div>
    </div>
  );
};

export default Hero;
