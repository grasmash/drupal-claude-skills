import Heading from "@/components/heading";
import Text from "@/components/text";
import { cva } from "class-variance-authority";
import { Image as ResponsiveImage } from "drupal-canvas";

const heroVariants = cva("mx-auto flex w-full max-w-[1360px] flex-col gap-8", {
  variants: {
    layout: {
      left_aligned: "items-start justify-between md:flex-row",
      centered: "flex-col items-center justify-center text-center",
    },
  },
  defaultVariants: {
    layout: "left_aligned",
  },
});

const TwoColumnText = ({
  layout,
  preHeading,
  heading,
  headingElement,
  headingSize = "large",
  text,
  buttons,
  textColor = "dark",
  image,
  rightColumn,
  textShadow,
}) => {
  return (
    <div className="flex w-full justify-start bg-cover bg-center bg-no-repeat py-24">
      <div className="mx-6 flex w-full items-center justify-center">
        <div className={heroVariants({ layout })}>
          <div
            className={`flex max-w-xl flex-col items-start justify-start gap-4 xl:max-w-lg ${layout === "centered" ? "items-center" : "items-start"}`}
          >
            <div className="mb-4">
              <Heading
                heading={heading}
                headingElement={headingElement}
                headingSize={headingSize}
                preHeading={preHeading}
                textColor={textColor}
                textShadow={textShadow}
              />
            </div>
            {text && (
              <Text
                className="mb-4"
                text={text}
                textColor={textColor}
                textSize="large"
                textShadow={textShadow}
              />
            )}
            <div
              className={`flex w-full min-w-3xs gap-4 ${layout === "centered" ? "justify-center" : "justify-start"}`}
            >
              {buttons}
            </div>
          </div>
          <div className="flex max-w-3xl">
            <ContentImage image={image} className="h-auto max-w-full" />
            {rightColumn}
          </div>
        </div>
      </div>
    </div>
  );
};

const ContentImage = ({ image, className }) => {
  if (!image) {
    return null;
  }
  const { src, alt, width, height } = image;
  return (
    <ResponsiveImage {...{ src, alt, width, height }} className={className} />
  );
};

export default TwoColumnText;
