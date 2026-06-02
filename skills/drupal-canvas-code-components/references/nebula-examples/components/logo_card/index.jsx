import { Image } from "drupal-canvas";

const LogoCard = ({ backgroundColor = "#F1F5F9", image }) => {
  const { src, alt, width, height } = image;
  return (
    <div
      className="align-center flex max-h-33 max-w-50 flex-col justify-center gap-4 rounded-2xl p-6 leading-[normal]"
      style={{ backgroundColor }}
    >
      <Image
        {...{ src, alt, width, height }}
        className="h-auto w-50 object-contain"
      />
    </div>
  );
};

export default LogoCard;
