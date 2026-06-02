import Image from "@/components/image";

export default {
  title: "Components/Image",
  component: Image,
};

export const Default = {
  args: {
    image: {
      src: "https://placehold.co/800x600@2x.png",
      alt: "Example image placeholder",
      width: 800,
      height: 600,
    },
  },
};

export const CustomImage = {
  args: {
    image: {
      src: "https://placehold.co/1200x800@2x.png",
      alt: "Wide landscape placeholder",
      width: 1200,
      height: 800,
    },
  },
};

export const SquareImage = {
  args: {
    image: {
      src: "https://placehold.co/600x600@2x.png",
      alt: "Square placeholder",
      width: 600,
      height: 600,
    },
  },
};

export const PortraitImage = {
  args: {
    image: {
      src: "https://placehold.co/400x600@2x.png",
      alt: "Portrait placeholder",
      width: 400,
      height: 600,
    },
  },
};
