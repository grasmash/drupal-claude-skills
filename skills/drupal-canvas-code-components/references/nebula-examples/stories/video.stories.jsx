import Video from "@/components/video";

export default {
  title: "Components/Video",
  component: Video,
};

export const Default = {
  args: {
    video: {
      src: "https://www.w3schools.com/html/mov_bbb.mp4",
      poster: "https://placehold.co/1920x1080.png?text=Widescreen",
    },
  },
};
