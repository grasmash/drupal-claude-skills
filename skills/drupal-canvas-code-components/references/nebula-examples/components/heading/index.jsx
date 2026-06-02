import { cva } from "class-variance-authority";
import { cn } from "drupal-canvas";

const containerVariants = cva("dark flex w-full flex-col", {
  variants: {
    layout: {
      left_aligned: "items-start text-left",
      center_aligned: "items-center text-center",
      right_aligned: "items-end text-right",
    },
  },
});

const preHeadingVariants = cva("mb-4 text-lg font-bold", {
  variants: {
    textColor: {
      dark: "text-primary-dark",
      light: "text-primary-light",
    },
    headingSize: {
      extra_large: "text-lg",
      large: "text-base",
      medium: "text-sm",
      small: "text-xs",
    },
    textShadow: {
      light: "text-shadow-sm",
      medium: "text-shadow-md",
      heavy: "text-shadow-lg",
    },
  },
});

const headingVariants = cva("leading-[normal] font-bold text-balance", {
  variants: {
    textColor: {
      dark: "text-black",
      light: "text-white",
    },
    headingSize: {
      extra_large: "text-6xl",
      large: "text-4xl",
      medium: "text-2xl",
      small: "text-lg",
    },
    textShadow: {
      light: "text-shadow-sm",
      medium: "text-shadow-md",
      heavy: "text-shadow-lg",
    },
  },
});

const Heading = ({
  className,
  heading,
  headingElement = "h2",
  headingSize = "extra_large",
  layout = "left_aligned",
  preHeading,
  textColor = "dark",
  textShadow,
}) => {
  const Heading = headingElement;
  return preHeading || heading ? (
    <div className={cn(containerVariants({ layout }), className)}>
      {preHeading && (
        <div
          className={preHeadingVariants({ textColor, headingSize, textShadow })}
        >
          {preHeading}
        </div>
      )}
      {heading && (
        <Heading
          className={headingVariants({ textColor, headingSize, textShadow })}
        >
          {heading}
        </Heading>
      )}
    </div>
  ) : null;
};

export default Heading;
