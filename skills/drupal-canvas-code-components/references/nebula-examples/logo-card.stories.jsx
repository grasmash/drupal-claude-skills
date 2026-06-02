import LogoCard from "@/components/logo_card";

const exampleArgs = {
  image: {
    src: "https://placehold.co/800x600@2x.png",
    alt: "Example image placeholder",
    width: 800,
    height: 600,
  },
};

export default {
  title: "Components/Logo Card",
  component: LogoCard,
  argTypes: {
    backgroundColor: {
      control: "color",
    },
  },
};

export const Default = {
  args: exampleArgs,
};

export const CustomBackground = {
  args: {
    ...exampleArgs,
    backgroundColor: "#E0F2FE",
  },
};

export const DarkBackground = {
  args: {
    ...exampleArgs,
    backgroundColor: "#1E293B",
  },
};
