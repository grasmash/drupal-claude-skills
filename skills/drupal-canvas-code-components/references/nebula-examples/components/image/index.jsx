import { Image as ResponsiveImage } from "drupal-canvas";

const Image = ({ image }) => {
  const { src, alt, width, height } = image;
  return (
    <ResponsiveImage
      {...{ src, alt, width, height }}
      className="my-8 max-w-full"
    />
  );
};

export default Image;
