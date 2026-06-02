const Video = ({ video }) => {
  return (
    <video className="w-full" controls>
      <source src={video.src} />
      <track kind="captions" />
    </video>
  );
};

export default Video;
