import Button from "@/components/button";
import Heading from "@/components/heading";
import { cva } from "class-variance-authority";
import { cn, FormattedText, Image } from "drupal-canvas";

const cardVariants = cva(
  "flex w-full max-w-md flex-col items-center gap-4 rounded-2xl pb-6 leading-[normal]",
  {
    variants: {
      layout: {
        left_aligned: "items-start text-left",
        center_aligned: "items-center text-center",
        right_aligned: "items-end text-right",
      },
      textColor: {
        Default: null,
        Dark: "text-primary-dark",
        Light: "text-white",
      },
      image: {
        true: null,
        false: "pt-8",
      },
    },
    defaultVariants: {
      textColor: "Default",
    },
  },
);

const Card = ({
  backgroundColor = "#ffffff",
  backgroundColorOnHover = "#E2E8F0",
  className,
  image,
  heading,
  headingElement = "h2",
  layout = "left_aligned",
  link,
  linkLabel,
  linkVariant = "link",
  text,
  textColor,
}) => {
  const cardBackgroundClassName = `card-${backgroundColor.substring(1)}`;
  const cardBackgroundClassNameOnHover = `card-${backgroundColorOnHover.substring(1)}`;
  const { src, alt, width, height } = image;

  return (
    <>
      <style>
        {`
          .${cardBackgroundClassName} {
            background-color: ${backgroundColor};
          }
          .${cardBackgroundClassNameOnHover}:hover {
            background-color: ${backgroundColorOnHover};
          }
        `}
      </style>
      <div
        className={cn(
          cardVariants({ layout, textColor, image: !!image }),
          cardBackgroundClassName,
          cardBackgroundClassNameOnHover,
          className,
        )}
      >
        {image && (
          <Image
            {...{ src, alt, width, height }}
            className="w-full rounded-2xl object-cover object-center"
          />
        )}
        <div className="px-6 pt-2">
          {heading && (
            <Heading
              className="mb-2"
              heading={heading}
              headingElement={headingElement}
              headingSize="small"
              layout={layout}
              textColor={textColor}
            />
          )}
          {text && (
            <FormattedText className="mb-4 leading-6">{text}</FormattedText>
          )}
          {link && linkLabel && (
            <Button link={link} variant={linkVariant}>
              {linkLabel}
            </Button>
          )}
        </div>
      </div>
    </>
  );
};

export default Card;
